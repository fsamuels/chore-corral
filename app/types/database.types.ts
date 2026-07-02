// Hand-written types for the tables the app queries so far, mirroring the M2
// migration (supabase/migrations/20260702154910_m2_schema_and_rls.sql).
// Replace with `supabase gen types typescript` output once a type-generation
// workflow exists; until then, extend this file as new tables come into use.

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
          created_at: string
        }
        Insert: {
          id?: string
          farm_id: string
          user_id: string
          created_at?: string
        }
        Update: {
          id?: string
          farm_id?: string
          user_id?: string
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
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: {
      task_priority: 'whenever' | 'soon' | 'urgent'
      task_status: 'not_started' | 'in_progress' | 'done'
    }
    CompositeTypes: Record<string, never>
  }
}
