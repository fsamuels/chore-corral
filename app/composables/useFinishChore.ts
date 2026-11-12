import type { Database } from '~/types/database.types'
import { changeTaskStatus, getTaskBriefs } from '~/services/tasks'
import {
  listCompletersForTasks,
  type TaskCompleter,
} from '~/services/completers'
import { listFarmMemberProfiles } from '~/services/members'
import { completerMemberItems } from '~/utils/completers'

/**
 * The running-timer dock's "Finish" flow: open the mark-done dialog
 * (`CompleteChoreDialog`) for the chore the timer is on, then — on confirm —
 * stop the timer and mark the chore done. Called once, from the default
 * layout, which renders the dialog from this state.
 *
 * Everything is keyed on the *task's own* farm rather than the active farm
 * (`useTasks().setStatus` uses the active one): the timer can be running on a
 * chore in another farm than the one currently selected, and a status change
 * there would otherwise fail with "Chore not found".
 *
 * Order matters. The dialog opens first with the timer still running, so
 * Cancel changes nothing. On confirm the timer is stopped *before* the status
 * change: `changeTaskStatus` doesn't touch time entries, so nothing else would
 * stop it, and a finished chore must not keep ticking. If the status change
 * then fails the timer stays stopped (the dialog stays open with the error,
 * and the dock resyncs) — the user's intent to stop is unambiguous, and
 * restarting a session would invent time they didn't work.
 */
export function useFinishChore() {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const { runningEntry, refresh, stop } = useRunningTimer()
  const { showToast } = useToast()
  const { notifyTasksChanged } = useTasksChanged()

  const open = ref(false)
  const busy = ref(false)
  const error = ref<string | null>(null)
  const memberItems = ref<ReturnType<typeof completerMemberItems>>([])
  const existingCompleters = ref<TaskCompleter[]>([])
  const actorUserId = computed(() => getActorUserId(user.value))

  // The chore being finished; its farm and title come from a fresh lookup
  // when the dialog opens (the dock only has the task id and title).
  let target: { taskId: string; farmId: string; title: string } | null = null

  // Latest-open-wins: a second tap (or a close) while the lookup is still in
  // flight must not let the first lookup open or fill the dialog late.
  let openSeq = 0

  async function begin(): Promise<void> {
    const entry = runningEntry.value
    if (!entry || busy.value) return
    const seq = ++openSeq
    try {
      const [brief] = await getTaskBriefs(supabase, [entry.task_id])
      if (!brief) throw new Error('Chore not found')
      // Members and existing completers are independent lookups.
      const [members, completersByTask] = await Promise.all([
        listFarmMemberProfiles(supabase, brief.farm_id),
        listCompletersForTasks(supabase, [brief.id]),
      ])
      // The timer moved to another chore while we were loading (sync poll).
      if (seq !== openSeq || runningEntry.value?.task_id !== brief.id) return
      target = { taskId: brief.id, farmId: brief.farm_id, title: brief.title }
      memberItems.value = completerMemberItems(members)
      existingCompleters.value = completersByTask.get(brief.id) ?? []
      error.value = null
      open.value = true
    } catch (e) {
      if (seq !== openSeq) return
      // Couldn't even load the dialog's data: say so, leave the timer alone.
      showToast(e instanceof Error ? e.message : 'Failed to open chore', {
        tone: 'error',
      })
    }
  }

  function cancel(): void {
    if (busy.value) return
    openSeq++
    open.value = false
  }

  async function confirm(input: {
    note: string
    completers: TaskCompleter[]
  }): Promise<void> {
    const current = target
    if (!current || busy.value) return
    const actor = actorUserId.value
    if (!actor) {
      error.value = 'No signed-in user'
      return
    }
    busy.value = true
    error.value = null
    try {
      // Stop only this chore's own timer; if it was already stopped (or
      // switched) from another device there's nothing to stop. `stop`
      // swallows its own failure by resyncing, so it can't block finishing.
      if (runningEntry.value?.task_id === current.taskId) {
        await stop()
        // `stop` resyncs instead of throwing; if the timer is still on this
        // chore afterwards the stop genuinely failed, so don't mark it done
        // with a session still ticking.
        if (runningEntry.value?.task_id === current.taskId) {
          throw new Error('Failed to stop the timer')
        }
      }
      await changeTaskStatus(supabase, {
        farmId: current.farmId,
        taskId: current.taskId,
        status: 'done',
        actorUserId: actor,
        note: input.note,
        completers: input.completers,
      })
      open.value = false
      showToast(`“${current.title}” marked done`)
      notifyTasksChanged()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to mark done'
    } finally {
      busy.value = false
      // Success or failure, the dock must reflect what actually happened.
      await refresh()
    }
  }

  // A timer started on another chore (here or, via the sync poll, on another
  // device) means the dock has moved on from the chore this dialog is for —
  // close it rather than finish something the user is no longer looking at.
  // A timer that merely stopped keeps the dialog: the chore can still be
  // marked done.
  watch(
    () => runningEntry.value?.task_id ?? null,
    (taskId) => {
      if (open.value && !busy.value && taskId && taskId !== target?.taskId) {
        cancel()
      }
    },
  )

  return {
    open,
    busy,
    error,
    memberItems,
    existingCompleters,
    actorUserId,
    begin,
    cancel,
    confirm,
  }
}
