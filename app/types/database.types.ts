// Hand-written types for the tables the app queries so far, mirroring the M2
// migration (supabase/migrations/20260702154910_m2_schema_and_rls.sql).
// Replace with `supabase gen types typescript` output once a type-generation
// workflow exists; until then, extend this file as new tables come into use.

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      farms: {
        Row: {
          id: string
          name: string
          address: string | null
          default_lat: number | null
          default_lng: number | null
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          address?: string | null
          default_lat?: number | null
          default_lng?: number | null
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          address?: string | null
          default_lat?: number | null
          default_lng?: number | null
          created_at?: string
        }
        Relationships: []
      }
      farm_memberships: {
        Row: {
          id: string
          farm_id: string
          user_id: string
          role: Database['public']['Enums']['farm_role']
          created_at: string
        }
        Insert: {
          id?: string
          farm_id: string
          user_id: string
          role?: Database['public']['Enums']['farm_role']
          created_at?: string
        }
        Update: {
          id?: string
          farm_id?: string
          user_id?: string
          role?: Database['public']['Enums']['farm_role']
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'farm_memberships_farm_id_fkey'
            columns: ['farm_id']
            isOneToOne: false
            referencedRelation: 'farms'
            referencedColumns: ['id']
          },
        ]
      }
      farm_invites: {
        Row: {
          id: string
          farm_id: string
          email: string
          role: Database['public']['Enums']['farm_role']
          invited_by: string
          created_at: string
          accepted_at: string | null
          accepted_by: string | null
        }
        Insert: {
          id?: string
          farm_id: string
          email: string
          role?: Database['public']['Enums']['farm_role']
          invited_by: string
          created_at?: string
          accepted_at?: string | null
          accepted_by?: string | null
        }
        Update: {
          id?: string
          farm_id?: string
          email?: string
          role?: Database['public']['Enums']['farm_role']
          invited_by?: string
          created_at?: string
          accepted_at?: string | null
          accepted_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'farm_invites_farm_id_fkey'
            columns: ['farm_id']
            isOneToOne: false
            referencedRelation: 'farms'
            referencedColumns: ['id']
          },
        ]
      }
      categories: {
        Row: {
          id: string
          farm_id: string
          name: string
          emoji: string | null
          deleted_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          farm_id: string
          name: string
          emoji?: string | null
          deleted_at?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          farm_id?: string
          name?: string
          emoji?: string | null
          deleted_at?: string | null
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'categories_farm_id_fkey'
            columns: ['farm_id']
            isOneToOne: false
            referencedRelation: 'farms'
            referencedColumns: ['id']
          },
        ]
      }
      locations: {
        Row: {
          id: string
          farm_id: string
          name: string
          lat: number
          lng: number
          deleted_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          farm_id: string
          name: string
          lat: number
          lng: number
          deleted_at?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          farm_id?: string
          name?: string
          lat?: number
          lng?: number
          deleted_at?: string | null
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'locations_farm_id_fkey'
            columns: ['farm_id']
            isOneToOne: false
            referencedRelation: 'farms'
            referencedColumns: ['id']
          },
        ]
      }
      tasks: {
        Row: {
          id: string
          farm_id: string
          title: string
          category_id: string | null
          priority: Database['public']['Enums']['task_priority']
          status: Database['public']['Enums']['task_status']
          due_date: string | null
          notes: string | null
          lat: number | null
          lng: number | null
          location_id: string | null
          created_at: string
          created_by: string
          completed_at: string | null
          estimated_minutes: number | null
        }
        Insert: {
          id?: string
          farm_id: string
          title: string
          category_id?: string | null
          priority: Database['public']['Enums']['task_priority']
          status?: Database['public']['Enums']['task_status']
          due_date?: string | null
          notes?: string | null
          lat?: number | null
          lng?: number | null
          location_id?: string | null
          created_at?: string
          created_by: string
          completed_at?: string | null
          estimated_minutes?: number | null
        }
        Update: {
          id?: string
          farm_id?: string
          title?: string
          category_id?: string | null
          priority?: Database['public']['Enums']['task_priority']
          status?: Database['public']['Enums']['task_status']
          due_date?: string | null
          notes?: string | null
          lat?: number | null
          lng?: number | null
          location_id?: string | null
          created_at?: string
          created_by?: string
          completed_at?: string | null
          estimated_minutes?: number | null
        }
        Relationships: [
          {
            foreignKeyName: 'tasks_farm_id_fkey'
            columns: ['farm_id']
            isOneToOne: false
            referencedRelation: 'farms'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'tasks_category_id_fkey'
            columns: ['category_id']
            isOneToOne: false
            referencedRelation: 'categories'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'tasks_location_id_fkey'
            columns: ['location_id']
            isOneToOne: false
            referencedRelation: 'locations'
            referencedColumns: ['id']
          },
        ]
      }
      tags: {
        Row: {
          id: string
          farm_id: string
          name: string
          created_at: string
        }
        Insert: {
          id?: string
          farm_id: string
          name: string
          created_at?: string
        }
        Update: {
          id?: string
          farm_id?: string
          name?: string
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'tags_farm_id_fkey'
            columns: ['farm_id']
            isOneToOne: false
            referencedRelation: 'farms'
            referencedColumns: ['id']
          },
        ]
      }
      task_tags: {
        Row: {
          task_id: string
          tag_id: string
        }
        Insert: {
          task_id: string
          tag_id: string
        }
        Update: {
          task_id?: string
          tag_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'task_tags_task_id_fkey'
            columns: ['task_id']
            isOneToOne: false
            referencedRelation: 'tasks'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'task_tags_tag_id_fkey'
            columns: ['tag_id']
            isOneToOne: false
            referencedRelation: 'tags'
            referencedColumns: ['id']
          },
        ]
      }
      task_completers: {
        Row: {
          id: string
          task_id: string
          user_id: string | null
          completer_name: string | null
        }
        Insert: {
          id?: string
          task_id: string
          user_id?: string | null
          completer_name?: string | null
        }
        Update: {
          id?: string
          task_id?: string
          user_id?: string | null
          completer_name?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'task_completers_task_id_fkey'
            columns: ['task_id']
            isOneToOne: false
            referencedRelation: 'tasks'
            referencedColumns: ['id']
          },
        ]
      }
      task_photos: {
        Row: {
          id: string
          task_id: string
          storage_path: string
          caption: string | null
          taken_at: string
        }
        Insert: {
          id?: string
          task_id: string
          storage_path: string
          caption?: string | null
          taken_at?: string
        }
        Update: {
          id?: string
          task_id?: string
          storage_path?: string
          caption?: string | null
          taken_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'task_photos_task_id_fkey'
            columns: ['task_id']
            isOneToOne: false
            referencedRelation: 'tasks'
            referencedColumns: ['id']
          },
        ]
      }
      task_shopping_items: {
        Row: {
          id: string
          task_id: string
          name: string
          checked: boolean
          created_at: string
        }
        Insert: {
          id?: string
          task_id: string
          name: string
          checked?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          task_id?: string
          name?: string
          checked?: boolean
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'task_shopping_items_task_id_fkey'
            columns: ['task_id']
            isOneToOne: false
            referencedRelation: 'tasks'
            referencedColumns: ['id']
          },
        ]
      }
      task_tools: {
        Row: {
          id: string
          task_id: string
          name: string
          checked: boolean
          created_at: string
        }
        Insert: {
          id?: string
          task_id: string
          name: string
          checked?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          task_id?: string
          name?: string
          checked?: boolean
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'task_tools_task_id_fkey'
            columns: ['task_id']
            isOneToOne: false
            referencedRelation: 'tasks'
            referencedColumns: ['id']
          },
        ]
      }
      task_time_entries: {
        Row: {
          id: string
          task_id: string
          user_id: string
          started_at: string
          ended_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          task_id: string
          user_id: string
          started_at?: string
          ended_at?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          task_id?: string
          user_id?: string
          started_at?: string
          ended_at?: string | null
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'task_time_entries_task_id_fkey'
            columns: ['task_id']
            isOneToOne: false
            referencedRelation: 'tasks'
            referencedColumns: ['id']
          },
        ]
      }
      activity_log: {
        Row: {
          id: string
          farm_id: string
          task_id: string | null
          event_type: string
          event_detail: Json
          actor_user_id: string
          created_at: string
        }
        Insert: {
          id?: string
          farm_id: string
          task_id?: string | null
          event_type: string
          event_detail: Json
          actor_user_id: string
          created_at?: string
        }
        Update: {
          id?: string
          farm_id?: string
          task_id?: string | null
          event_type?: string
          event_detail?: Json
          actor_user_id?: string
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'activity_log_farm_id_fkey'
            columns: ['farm_id']
            isOneToOne: false
            referencedRelation: 'farms'
            referencedColumns: ['id']
          },
        ]
      }
    }
    Views: {
      farm_member_profiles: {
        Row: {
          farm_id: string
          user_id: string
          email: string | null
          role: Database['public']['Enums']['farm_role']
        }
        Relationships: []
      }
      farm_recent_activity: {
        Row: {
          farm_id: string
          last_activity_at: string
        }
        Relationships: []
      }
    }
    Functions: {
      accept_farm_invites: {
        Args: Record<string, never>
        Returns: string[]
      }
      create_farm: {
        Args: { farm_name: string; farm_address?: string | null }
        Returns: string
      }
    }
    Enums: {
      farm_role: 'owner' | 'member'
      task_priority: 'whenever' | 'soon' | 'urgent'
      task_status: 'not_started' | 'in_progress' | 'done'
    }
    CompositeTypes: Record<string, never>
  }
}
