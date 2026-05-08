export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.4"
  }
  public: {
    Tables: {
      admin_audit_log: {
        Row: {
          action: string
          admin_id: string | null
          created_at: string | null
          entity: string
          entity_id: string | null
          id: string
          ip_address: string | null
          new_data: Json | null
          old_data: Json | null
          user_agent: string | null
        }
        Insert: {
          action: string
          admin_id?: string | null
          created_at?: string | null
          entity?: string
          entity_id?: string | null
          id?: string
          ip_address?: string | null
          new_data?: Json | null
          old_data?: Json | null
          user_agent?: string | null
        }
        Update: {
          action?: string
          admin_id?: string | null
          created_at?: string | null
          entity?: string
          entity_id?: string | null
          id?: string
          ip_address?: string | null
          new_data?: Json | null
          old_data?: Json | null
          user_agent?: string | null
        }
        Relationships: []
      }
      admin_audit_logs: {
        Row: {
          action: string
          actor_email: string | null
          actor_user_id: string | null
          created_at: string
          entity: string
          entity_id: string | null
          id: string
          ip_address: string | null
          metadata: Json | null
          new_values: Json | null
          old_values: Json | null
          user_agent: string | null
        }
        Insert: {
          action: string
          actor_email?: string | null
          actor_user_id?: string | null
          created_at?: string
          entity: string
          entity_id?: string | null
          id?: string
          ip_address?: string | null
          metadata?: Json | null
          new_values?: Json | null
          old_values?: Json | null
          user_agent?: string | null
        }
        Update: {
          action?: string
          actor_email?: string | null
          actor_user_id?: string | null
          created_at?: string
          entity?: string
          entity_id?: string | null
          id?: string
          ip_address?: string | null
          metadata?: Json | null
          new_values?: Json | null
          old_values?: Json | null
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_audit_logs_actor_user_id_fkey"
            columns: ["actor_user_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_checklist: {
        Row: {
          category: string
          created_at: string | null
          id: string
          is_active: boolean | null
          label_ar: string
          label_en: string
          sort_order: number | null
        }
        Insert: {
          category: string
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          label_ar: string
          label_en: string
          sort_order?: number | null
        }
        Update: {
          category?: string
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          label_ar?: string
          label_en?: string
          sort_order?: number | null
        }
        Relationships: []
      }
      admin_courses: {
        Row: {
          created_at: string
          created_by: string | null
          department_id: string
          description: string | null
          description_ar: string | null
          id: string
          is_active: boolean | null
          name: string
          name_ar: string | null
          slug: string
          sort_order: number | null
          thumbnail_url: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          department_id: string
          description?: string | null
          description_ar?: string | null
          id?: string
          is_active?: boolean | null
          name: string
          name_ar?: string | null
          slug: string
          sort_order?: number | null
          thumbnail_url?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          department_id?: string
          description?: string | null
          description_ar?: string | null
          id?: string
          is_active?: boolean | null
          name?: string
          name_ar?: string | null
          slug?: string
          sort_order?: number | null
          thumbnail_url?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_courses_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_courses_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "admin_departments"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_departments: {
        Row: {
          bg_color: string | null
          created_at: string
          created_by: string | null
          description: string | null
          description_ar: string | null
          icon: string | null
          icon_type: string | null
          id: string
          is_active: boolean | null
          lucide_icon: string | null
          name: string
          name_ar: string | null
          slug: string
          sort_order: number | null
          tile_type: string | null
          updated_at: string
        }
        Insert: {
          bg_color?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          description_ar?: string | null
          icon?: string | null
          icon_type?: string | null
          id?: string
          is_active?: boolean | null
          lucide_icon?: string | null
          name: string
          name_ar?: string | null
          slug: string
          sort_order?: number | null
          tile_type?: string | null
          updated_at?: string
        }
        Update: {
          bg_color?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          description_ar?: string | null
          icon?: string | null
          icon_type?: string | null
          id?: string
          is_active?: boolean | null
          lucide_icon?: string | null
          name?: string
          name_ar?: string | null
          slug?: string
          sort_order?: number | null
          tile_type?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_departments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_faq: {
        Row: {
          answer_ar: string
          answer_en: string
          category: string
          created_at: string | null
          id: string
          is_active: boolean | null
          question_ar: string
          question_en: string
          sort_order: number | null
        }
        Insert: {
          answer_ar: string
          answer_en: string
          category: string
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          question_ar: string
          question_en: string
          sort_order?: number | null
        }
        Update: {
          answer_ar?: string
          answer_en?: string
          category?: string
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          question_ar?: string
          question_en?: string
          sort_order?: number | null
        }
        Relationships: []
      }
      admin_lecture_assets: {
        Row: {
          created_at: string
          file_name: string
          file_size: number | null
          id: string
          is_primary: boolean | null
          lecture_id: string
          mime_type: string | null
          sort_order: number | null
          storage_path: string
          type: Database["public"]["Enums"]["asset_type"]
          uploaded_by: string | null
          version: number | null
        }
        Insert: {
          created_at?: string
          file_name: string
          file_size?: number | null
          id?: string
          is_primary?: boolean | null
          lecture_id: string
          mime_type?: string | null
          sort_order?: number | null
          storage_path: string
          type?: Database["public"]["Enums"]["asset_type"]
          uploaded_by?: string | null
          version?: number | null
        }
        Update: {
          created_at?: string
          file_name?: string
          file_size?: number | null
          id?: string
          is_primary?: boolean | null
          lecture_id?: string
          mime_type?: string | null
          sort_order?: number | null
          storage_path?: string
          type?: Database["public"]["Enums"]["asset_type"]
          uploaded_by?: string | null
          version?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_lecture_assets_lecture_id_fkey"
            columns: ["lecture_id"]
            isOneToOne: false
            referencedRelation: "admin_lectures"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_lecture_assets_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_lectures: {
        Row: {
          course_id: string
          created_at: string
          created_by: string | null
          description: string | null
          description_ar: string | null
          duration_minutes: number | null
          id: string
          instructor_id: string | null
          published_at: string | null
          scheduled_publish_at: string | null
          sort_order: number | null
          status: Database["public"]["Enums"]["lecture_status"]
          title: string
          title_ar: string | null
          updated_at: string
          version: number | null
        }
        Insert: {
          course_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          description_ar?: string | null
          duration_minutes?: number | null
          id?: string
          instructor_id?: string | null
          published_at?: string | null
          scheduled_publish_at?: string | null
          sort_order?: number | null
          status?: Database["public"]["Enums"]["lecture_status"]
          title: string
          title_ar?: string | null
          updated_at?: string
          version?: number | null
        }
        Update: {
          course_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          description_ar?: string | null
          duration_minutes?: number | null
          id?: string
          instructor_id?: string | null
          published_at?: string | null
          scheduled_publish_at?: string | null
          sort_order?: number | null
          status?: Database["public"]["Enums"]["lecture_status"]
          title?: string
          title_ar?: string | null
          updated_at?: string
          version?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_lectures_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "admin_courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_lectures_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_lectures_instructor_id_fkey"
            columns: ["instructor_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_legal_sections: {
        Row: {
          content_ar: string | null
          content_en: string | null
          created_at: string | null
          icon: string | null
          id: string
          is_active: boolean | null
          slug: string
          sort_order: number | null
          title_ar: string
          title_en: string
        }
        Insert: {
          content_ar?: string | null
          content_en?: string | null
          created_at?: string | null
          icon?: string | null
          id?: string
          is_active?: boolean | null
          slug: string
          sort_order?: number | null
          title_ar: string
          title_en: string
        }
        Update: {
          content_ar?: string | null
          content_en?: string | null
          created_at?: string | null
          icon?: string | null
          id?: string
          is_active?: boolean | null
          slug?: string
          sort_order?: number | null
          title_ar?: string
          title_en?: string
        }
        Relationships: []
      }
      admin_notification_reads: {
        Row: {
          id: string
          notification_id: string
          read_at: string
          user_id: string
        }
        Insert: {
          id?: string
          notification_id: string
          read_at?: string
          user_id: string
        }
        Update: {
          id?: string
          notification_id?: string
          read_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_notification_reads_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "admin_notifications"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_notifications: {
        Row: {
          body: string
          body_ar: string | null
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean | null
          scheduled_at: string | null
          sent_at: string | null
          target_type: Database["public"]["Enums"]["notification_target_type"]
          target_value: string | null
          title: string
          title_ar: string | null
        }
        Insert: {
          body: string
          body_ar?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean | null
          scheduled_at?: string | null
          sent_at?: string | null
          target_type?: Database["public"]["Enums"]["notification_target_type"]
          target_value?: string | null
          title: string
          title_ar?: string | null
        }
        Update: {
          body?: string
          body_ar?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean | null
          scheduled_at?: string | null
          sent_at?: string | null
          target_type?: Database["public"]["Enums"]["notification_target_type"]
          target_value?: string | null
          title?: string
          title_ar?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_notifications_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_permissions: {
        Row: {
          category: string
          created_at: string
          description: string | null
          description_ar: string | null
          display_name: string
          display_name_ar: string | null
          id: string
          key: string
        }
        Insert: {
          category?: string
          created_at?: string
          description?: string | null
          description_ar?: string | null
          display_name: string
          display_name_ar?: string | null
          id?: string
          key: string
        }
        Update: {
          category?: string
          created_at?: string
          description?: string | null
          description_ar?: string | null
          display_name?: string
          display_name_ar?: string | null
          id?: string
          key?: string
        }
        Relationships: []
      }
      admin_role_permissions: {
        Row: {
          created_at: string
          id: string
          permission_id: string
          role_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          permission_id: string
          role_id: string
        }
        Update: {
          created_at?: string
          id?: string
          permission_id?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_role_permissions_permission_id_fkey"
            columns: ["permission_id"]
            isOneToOne: false
            referencedRelation: "admin_permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_role_permissions_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "admin_roles"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_roles: {
        Row: {
          created_at: string
          description: string | null
          description_ar: string | null
          display_name: string
          display_name_ar: string | null
          id: string
          is_system: boolean | null
          name: Database["public"]["Enums"]["admin_role"]
        }
        Insert: {
          created_at?: string
          description?: string | null
          description_ar?: string | null
          display_name: string
          display_name_ar?: string | null
          id?: string
          is_system?: boolean | null
          name: Database["public"]["Enums"]["admin_role"]
        }
        Update: {
          created_at?: string
          description?: string | null
          description_ar?: string | null
          display_name?: string
          display_name_ar?: string | null
          id?: string
          is_system?: boolean | null
          name?: Database["public"]["Enums"]["admin_role"]
        }
        Relationships: []
      }
      admin_settings: {
        Row: {
          category: string
          description: string | null
          description_ar: string | null
          id: string
          is_sensitive: boolean | null
          key: string
          updated_at: string
          updated_by: string | null
          value_json: Json
        }
        Insert: {
          category?: string
          description?: string | null
          description_ar?: string | null
          id?: string
          is_sensitive?: boolean | null
          key: string
          updated_at?: string
          updated_by?: string | null
          value_json?: Json
        }
        Update: {
          category?: string
          description?: string | null
          description_ar?: string | null
          id?: string
          is_sensitive?: boolean | null
          key?: string
          updated_at?: string
          updated_by?: string | null
          value_json?: Json
        }
        Relationships: [
          {
            foreignKeyName: "admin_settings_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_support_tickets: {
        Row: {
          assigned_to: string | null
          category: string | null
          created_at: string | null
          description: string | null
          id: string
          priority: string | null
          status: string | null
          subject: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          assigned_to?: string | null
          category?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          priority?: string | null
          status?: string | null
          subject: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          assigned_to?: string | null
          category?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          priority?: string | null
          status?: string | null
          subject?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_support_tickets_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_support_tickets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_user_roles: {
        Row: {
          assigned_at: string
          assigned_by: string | null
          id: string
          role_id: string
          user_id: string
        }
        Insert: {
          assigned_at?: string
          assigned_by?: string | null
          id?: string
          role_id: string
          user_id: string
        }
        Update: {
          assigned_at?: string
          assigned_by?: string | null
          id?: string
          role_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_user_roles_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_user_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "admin_roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_user_roles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_users: {
        Row: {
          avatar_url: string | null
          created_at: string
          email: string
          failed_login_attempts: number | null
          full_name: string
          full_name_ar: string | null
          id: string
          last_login_at: string | null
          locked_until: string | null
          login_count: number | null
          mfa_enabled: boolean | null
          phone: string | null
          role: string | null
          session_expires_at: string | null
          status: Database["public"]["Enums"]["admin_status"]
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          email: string
          failed_login_attempts?: number | null
          full_name: string
          full_name_ar?: string | null
          id?: string
          last_login_at?: string | null
          locked_until?: string | null
          login_count?: number | null
          mfa_enabled?: boolean | null
          phone?: string | null
          role?: string | null
          session_expires_at?: string | null
          status?: Database["public"]["Enums"]["admin_status"]
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          email?: string
          failed_login_attempts?: number | null
          full_name?: string
          full_name_ar?: string | null
          id?: string
          last_login_at?: string | null
          locked_until?: string | null
          login_count?: number | null
          mfa_enabled?: boolean | null
          phone?: string | null
          role?: string | null
          session_expires_at?: string | null
          status?: Database["public"]["Enums"]["admin_status"]
          updated_at?: string
        }
        Relationships: []
      }
      ai_conversations: {
        Row: {
          created_at: string
          id: string
          profile_id: string
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          profile_id: string
          title?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          profile_id?: string
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      ai_messages: {
        Row: {
          content: string
          conversation_id: string | null
          created_at: string
          id: string
          profile_id: string
          role: string
        }
        Insert: {
          content: string
          conversation_id?: string | null
          created_at?: string
          id?: string
          profile_id: string
          role: string
        }
        Update: {
          content?: string
          conversation_id?: string | null
          created_at?: string
          id?: string
          profile_id?: string
          role?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "ai_conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      app_comments: {
        Row: {
          content: string
          created_at: string
          id: string
          profile_id: string
          target_id: string
          target_type: string
        }
        Insert: {
          content: string
          created_at?: string
          id?: string
          profile_id: string
          target_id: string
          target_type: string
        }
        Update: {
          content?: string
          created_at?: string
          id?: string
          profile_id?: string
          target_id?: string
          target_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "app_comments_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      app_config: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          key: string
          updated_at: string | null
          value: string
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          key: string
          updated_at?: string | null
          value: string
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          key?: string
          updated_at?: string | null
          value?: string
        }
        Relationships: []
      }
      app_reposts: {
        Row: {
          created_at: string
          id: string
          profile_id: string
          target_id: string
          target_type: string
        }
        Insert: {
          created_at?: string
          id?: string
          profile_id: string
          target_id: string
          target_type: string
        }
        Update: {
          created_at?: string
          id?: string
          profile_id?: string
          target_id?: string
          target_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "app_reposts_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      automation_rules: {
        Row: {
          action: Json | null
          condition: Json | null
          created_at: string | null
          id: string
          is_active: boolean | null
          name: string | null
        }
        Insert: {
          action?: Json | null
          condition?: Json | null
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          name?: string | null
        }
        Update: {
          action?: Json | null
          condition?: Json | null
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          name?: string | null
        }
        Relationships: []
      }
      badge_requests: {
        Row: {
          created_at: string | null
          id: string
          profile_id: string
          reason: string | null
          status: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          profile_id: string
          reason?: string | null
          status?: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          profile_id?: string
          reason?: string | null
          status?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "badge_requests_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      blocked_profiles: {
        Row: {
          blocked_profile_id: string
          blocker_profile_id: string
          created_at: string
          id: string
        }
        Insert: {
          blocked_profile_id: string
          blocker_profile_id: string
          created_at?: string
          id?: string
        }
        Update: {
          blocked_profile_id?: string
          blocker_profile_id?: string
          created_at?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "blocked_profiles_blocked_profile_id_fkey"
            columns: ["blocked_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "blocked_profiles_blocker_profile_id_fkey"
            columns: ["blocker_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      blocked_users: {
        Row: {
          blocked_at: string | null
          blocked_id: string
          blocker_id: string
          id: string
          reason: string | null
        }
        Insert: {
          blocked_at?: string | null
          blocked_id: string
          blocker_id: string
          id?: string
          reason?: string | null
        }
        Update: {
          blocked_at?: string | null
          blocked_id?: string
          blocker_id?: string
          id?: string
          reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "blocked_users_blocked_id_fkey"
            columns: ["blocked_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "blocked_users_blocker_id_fkey"
            columns: ["blocker_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      capture_attempts: {
        Row: {
          attempt_reason: string | null
          attempt_type: string
          created_at: string
          device_info: Json | null
          id: string
          ip_address: string | null
          profile_id: string
        }
        Insert: {
          attempt_reason?: string | null
          attempt_type: string
          created_at?: string
          device_info?: Json | null
          id?: string
          ip_address?: string | null
          profile_id: string
        }
        Update: {
          attempt_reason?: string | null
          attempt_type?: string
          created_at?: string
          device_info?: Json | null
          id?: string
          ip_address?: string | null
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "capture_attempts_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      comment_likes: {
        Row: {
          comment_id: string
          comment_type: string
          created_at: string
          id: string
          profile_id: string
        }
        Insert: {
          comment_id: string
          comment_type: string
          created_at?: string
          id?: string
          profile_id: string
        }
        Update: {
          comment_id?: string
          comment_type?: string
          created_at?: string
          id?: string
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comment_likes_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      connection_requests: {
        Row: {
          created_at: string
          id: string
          message: string | null
          receiver_profile_id: string
          requester_profile_id: string
          responded_at: string | null
          status: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          message?: string | null
          receiver_profile_id: string
          requester_profile_id: string
          responded_at?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          message?: string | null
          receiver_profile_id?: string
          requester_profile_id?: string
          responded_at?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "connection_requests_receiver_profile_id_fkey"
            columns: ["receiver_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "connection_requests_requester_profile_id_fkey"
            columns: ["requester_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      contractor_details: {
        Row: {
          company_name: string | null
          created_at: string | null
          employees_count: number | null
          id: string
          profile_id: string
          status: Database["public"]["Enums"]["contractor_status"] | null
        }
        Insert: {
          company_name?: string | null
          created_at?: string | null
          employees_count?: number | null
          id?: string
          profile_id: string
          status?: Database["public"]["Enums"]["contractor_status"] | null
        }
        Update: {
          company_name?: string | null
          created_at?: string | null
          employees_count?: number | null
          id?: string
          profile_id?: string
          status?: Database["public"]["Enums"]["contractor_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "contractor_details_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          created_at: string
          id: string
          last_message: string | null
          last_message_at: string | null
          participant_one: string
          participant_two: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          last_message?: string | null
          last_message_at?: string | null
          participant_one: string
          participant_two: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          last_message?: string | null
          last_message_at?: string | null
          participant_one?: string
          participant_two?: string
          updated_at?: string
        }
        Relationships: []
      }
      course_progress: {
        Row: {
          completed_at: string | null
          course_id: string
          created_at: string
          id: string
          is_completed: boolean
          last_watched_at: string | null
          profile_id: string
          progress_percentage: number
        }
        Insert: {
          completed_at?: string | null
          course_id: string
          created_at?: string
          id?: string
          is_completed?: boolean
          last_watched_at?: string | null
          profile_id: string
          progress_percentage?: number
        }
        Update: {
          completed_at?: string | null
          course_id?: string
          created_at?: string
          id?: string
          is_completed?: boolean
          last_watched_at?: string | null
          profile_id?: string
          progress_percentage?: number
        }
        Relationships: [
          {
            foreignKeyName: "course_progress_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "course_progress_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      courses: {
        Row: {
          category: Database["public"]["Enums"]["course_category"]
          created_at: string
          description_ar: string | null
          description_en: string | null
          duration_minutes: number
          id: string
          is_active: boolean
          sort_order: number
          thumbnail_url: string | null
          title_ar: string
          title_en: string
          updated_at: string
          video_url: string
        }
        Insert: {
          category: Database["public"]["Enums"]["course_category"]
          created_at?: string
          description_ar?: string | null
          description_en?: string | null
          duration_minutes?: number
          id?: string
          is_active?: boolean
          sort_order?: number
          thumbnail_url?: string | null
          title_ar: string
          title_en: string
          updated_at?: string
          video_url: string
        }
        Update: {
          category?: Database["public"]["Enums"]["course_category"]
          created_at?: string
          description_ar?: string | null
          description_en?: string | null
          duration_minutes?: number
          id?: string
          is_active?: boolean
          sort_order?: number
          thumbnail_url?: string | null
          title_ar?: string
          title_en?: string
          updated_at?: string
          video_url?: string
        }
        Relationships: []
      }
      craftsman_details: {
        Row: {
          created_at: string | null
          hourly_rate: number | null
          id: string
          profile_id: string
          specialization: Database["public"]["Enums"]["craftsman_specialization"]
        }
        Insert: {
          created_at?: string | null
          hourly_rate?: number | null
          id?: string
          profile_id: string
          specialization: Database["public"]["Enums"]["craftsman_specialization"]
        }
        Update: {
          created_at?: string | null
          hourly_rate?: number | null
          id?: string
          profile_id?: string
          specialization?: Database["public"]["Enums"]["craftsman_specialization"]
        }
        Relationships: [
          {
            foreignKeyName: "craftsman_details_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      device_tokens: {
        Row: {
          created_at: string
          id: string
          platform: string
          token: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          platform?: string
          token: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          platform?: string
          token?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      engineer_details: {
        Row: {
          company_name: string | null
          created_at: string | null
          id: string
          license_number: string | null
          profile_id: string
          specialization: Database["public"]["Enums"]["engineer_specialization"]
        }
        Insert: {
          company_name?: string | null
          created_at?: string | null
          id?: string
          license_number?: string | null
          profile_id: string
          specialization: Database["public"]["Enums"]["engineer_specialization"]
        }
        Update: {
          company_name?: string | null
          created_at?: string | null
          id?: string
          license_number?: string | null
          profile_id?: string
          specialization?: Database["public"]["Enums"]["engineer_specialization"]
        }
        Relationships: [
          {
            foreignKeyName: "engineer_details_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      engineer_notes: {
        Row: {
          content: string
          created_at: string
          id: string
          profile_id: string
          title: string
          updated_at: string
        }
        Insert: {
          content: string
          created_at?: string
          id?: string
          profile_id: string
          title: string
          updated_at?: string
        }
        Update: {
          content?: string
          created_at?: string
          id?: string
          profile_id?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineer_notes_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      followers: {
        Row: {
          created_at: string
          follower_id: string
          following_id: string
          id: string
        }
        Insert: {
          created_at?: string
          follower_id: string
          following_id: string
          id?: string
        }
        Update: {
          created_at?: string
          follower_id?: string
          following_id?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "followers_follower_id_fkey"
            columns: ["follower_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "followers_following_id_fkey"
            columns: ["following_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      job_requests: {
        Row: {
          budget_max: number | null
          budget_min: number | null
          created_at: string | null
          description: string
          expires_at: string | null
          governorate: Database["public"]["Enums"]["governorate"]
          id: string
          is_active: boolean | null
          profile_id: string
          required_role: Database["public"]["Enums"]["user_role"] | null
          required_specialization: string | null
          title: string
        }
        Insert: {
          budget_max?: number | null
          budget_min?: number | null
          created_at?: string | null
          description: string
          expires_at?: string | null
          governorate: Database["public"]["Enums"]["governorate"]
          id?: string
          is_active?: boolean | null
          profile_id: string
          required_role?: Database["public"]["Enums"]["user_role"] | null
          required_specialization?: string | null
          title: string
        }
        Update: {
          budget_max?: number | null
          budget_min?: number | null
          created_at?: string | null
          description?: string
          expires_at?: string | null
          governorate?: Database["public"]["Enums"]["governorate"]
          id?: string
          is_active?: boolean | null
          profile_id?: string
          required_role?: Database["public"]["Enums"]["user_role"] | null
          required_specialization?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "job_requests_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      machinery_details: {
        Row: {
          created_at: string | null
          daily_rate: number | null
          hourly_rate: number | null
          id: string
          is_available: boolean | null
          machinery_model: string | null
          machinery_name: string | null
          profile_id: string
          specialization: Database["public"]["Enums"]["machinery_specialization"]
        }
        Insert: {
          created_at?: string | null
          daily_rate?: number | null
          hourly_rate?: number | null
          id?: string
          is_available?: boolean | null
          machinery_model?: string | null
          machinery_name?: string | null
          profile_id: string
          specialization: Database["public"]["Enums"]["machinery_specialization"]
        }
        Update: {
          created_at?: string | null
          daily_rate?: number | null
          hourly_rate?: number | null
          id?: string
          is_available?: boolean | null
          machinery_model?: string | null
          machinery_name?: string | null
          profile_id?: string
          specialization?: Database["public"]["Enums"]["machinery_specialization"]
        }
        Relationships: [
          {
            foreignKeyName: "machinery_details_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          audio_duration: number | null
          audio_url: string | null
          content: string
          conversation_id: string
          created_at: string
          id: string
          image_url: string | null
          is_read: boolean
          message_type: string
          read_at: string | null
          sender_id: string
        }
        Insert: {
          audio_duration?: number | null
          audio_url?: string | null
          content: string
          conversation_id: string
          created_at?: string
          id?: string
          image_url?: string | null
          is_read?: boolean
          message_type?: string
          read_at?: string | null
          sender_id: string
        }
        Update: {
          audio_duration?: number | null
          audio_url?: string | null
          content?: string
          conversation_id?: string
          created_at?: string
          id?: string
          image_url?: string | null
          is_read?: boolean
          message_type?: string
          read_at?: string | null
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      muted_conversations: {
        Row: {
          conversation_id: string
          id: string
          muted_at: string | null
          profile_id: string
        }
        Insert: {
          conversation_id: string
          id?: string
          muted_at?: string | null
          profile_id: string
        }
        Update: {
          conversation_id?: string
          id?: string
          muted_at?: string | null
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "muted_conversations_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "muted_conversations_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          action_url: string | null
          created_at: string
          id: string
          is_read: boolean
          message: string
          profile_id: string
          title: string
          type: string
        }
        Insert: {
          action_url?: string | null
          created_at?: string
          id?: string
          is_read?: boolean
          message: string
          profile_id: string
          title: string
          type?: string
        }
        Update: {
          action_url?: string | null
          created_at?: string
          id?: string
          is_read?: boolean
          message?: string
          profile_id?: string
          title?: string
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      otp_verifications: {
        Row: {
          attempts: number
          code: string
          created_at: string
          expires_at: string
          id: string
          phone_local10: string
          verified: boolean
        }
        Insert: {
          attempts?: number
          code: string
          created_at?: string
          expires_at: string
          id?: string
          phone_local10: string
          verified?: boolean
        }
        Update: {
          attempts?: number
          code?: string
          created_at?: string
          expires_at?: string
          id?: string
          phone_local10?: string
          verified?: boolean
        }
        Relationships: []
      }
      payment_history: {
        Row: {
          amount: number
          created_at: string
          currency: string
          id: string
          paid_at: string
          payment_method: string
          period_end: string
          period_start: string
          profile_id: string
          status: string
          subscription_id: string | null
          transaction_id: string | null
        }
        Insert: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          paid_at?: string
          payment_method?: string
          period_end?: string
          period_start?: string
          profile_id: string
          status?: string
          subscription_id?: string | null
          transaction_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          paid_at?: string
          payment_method?: string
          period_end?: string
          period_start?: string
          profile_id?: string
          status?: string
          subscription_id?: string | null
          transaction_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_history_subscription_id_fkey"
            columns: ["subscription_id"]
            isOneToOne: false
            referencedRelation: "subscriptions"
            referencedColumns: ["id"]
          },
        ]
      }
      permissions: {
        Row: {
          description: string | null
          id: string
          name: string
        }
        Insert: {
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      post_comments: {
        Row: {
          content: string
          created_at: string
          id: string
          likes_count: number | null
          post_id: string
          profile_id: string
          updated_at: string
        }
        Insert: {
          content: string
          created_at?: string
          id?: string
          likes_count?: number | null
          post_id: string
          profile_id: string
          updated_at?: string
        }
        Update: {
          content?: string
          created_at?: string
          id?: string
          likes_count?: number | null
          post_id?: string
          profile_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_comments_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      post_likes: {
        Row: {
          created_at: string
          id: string
          post_id: string
          profile_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          post_id: string
          profile_id: string
        }
        Update: {
          created_at?: string
          id?: string
          post_id?: string
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_likes_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_likes_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      post_reports: {
        Row: {
          admin_notes: string | null
          created_at: string
          id: string
          post_id: string
          reason: string
          reporter_id: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
        }
        Insert: {
          admin_notes?: string | null
          created_at?: string
          id?: string
          post_id: string
          reason: string
          reporter_id: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          admin_notes?: string | null
          created_at?: string
          id?: string
          post_id?: string
          reason?: string
          reporter_id?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_reports_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_reports_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      posts: {
        Row: {
          archived_at: string | null
          comments_count: number
          content: string
          created_at: string | null
          id: string
          image_url: string | null
          is_active: boolean | null
          is_archived: boolean | null
          likes_count: number
          post_type: string | null
          profile_id: string
          updated_at: string | null
        }
        Insert: {
          archived_at?: string | null
          comments_count?: number
          content: string
          created_at?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean | null
          is_archived?: boolean | null
          likes_count?: number
          post_type?: string | null
          profile_id: string
          updated_at?: string | null
        }
        Update: {
          archived_at?: string | null
          comments_count?: number
          content?: string
          created_at?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean | null
          is_archived?: boolean | null
          likes_count?: number
          post_type?: string | null
          profile_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      processed_transactions: {
        Row: {
          created_at: string | null
          id: string
          status: string | null
          transaction_id: string
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          status?: string | null
          transaction_id: string
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          status?: string | null
          transaction_id?: string
          user_id?: string | null
        }
        Relationships: []
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          cover_photo_url: string | null
          created_at: string | null
          date_of_birth: string | null
          email: string | null
          experience_years: number | null
          facebook_url: string | null
          followers_count: number | null
          following_count: number | null
          full_name: string | null
          governorate: Database["public"]["Enums"]["governorate"] | null
          has_pro_badge: boolean | null
          id: string
          id_document_url: string | null
          instagram_url: string | null
          is_verified: boolean | null
          phone: string | null
          posts_count: number | null
          projects_count: number | null
          rating: number | null
          role: Database["public"]["Enums"]["user_role"] | null
          subscription_expires_at: string | null
          subscription_status: string | null
          total_reviews: number | null
          updated_at: string | null
          user_id: string
          username: string | null
          verification_rejection_reason: string | null
          verification_status: string | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          cover_photo_url?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          email?: string | null
          experience_years?: number | null
          facebook_url?: string | null
          followers_count?: number | null
          following_count?: number | null
          full_name?: string | null
          governorate?: Database["public"]["Enums"]["governorate"] | null
          has_pro_badge?: boolean | null
          id?: string
          id_document_url?: string | null
          instagram_url?: string | null
          is_verified?: boolean | null
          phone?: string | null
          posts_count?: number | null
          projects_count?: number | null
          rating?: number | null
          role?: Database["public"]["Enums"]["user_role"] | null
          subscription_expires_at?: string | null
          subscription_status?: string | null
          total_reviews?: number | null
          updated_at?: string | null
          user_id: string
          username?: string | null
          verification_rejection_reason?: string | null
          verification_status?: string | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          cover_photo_url?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          email?: string | null
          experience_years?: number | null
          facebook_url?: string | null
          followers_count?: number | null
          following_count?: number | null
          full_name?: string | null
          governorate?: Database["public"]["Enums"]["governorate"] | null
          has_pro_badge?: boolean | null
          id?: string
          id_document_url?: string | null
          instagram_url?: string | null
          is_verified?: boolean | null
          phone?: string | null
          posts_count?: number | null
          projects_count?: number | null
          rating?: number | null
          role?: Database["public"]["Enums"]["user_role"] | null
          subscription_expires_at?: string | null
          subscription_status?: string | null
          total_reviews?: number | null
          updated_at?: string | null
          user_id?: string
          username?: string | null
          verification_rejection_reason?: string | null
          verification_status?: string | null
        }
        Relationships: []
      }
      project_applications: {
        Row: {
          attachments_count: number
          created_at: string
          files: Json
          id: string
          message: string
          profile_id: string
          project_id: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          subject: string
          updated_at: string
        }
        Insert: {
          attachments_count?: number
          created_at?: string
          files?: Json
          id?: string
          message: string
          profile_id: string
          project_id: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          subject: string
          updated_at?: string
        }
        Update: {
          attachments_count?: number
          created_at?: string
          files?: Json
          id?: string
          message?: string
          profile_id?: string
          project_id?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          subject?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "project_applications_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "project_applications_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "project_applications_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      project_attachments: {
        Row: {
          created_at: string
          file_name: string
          file_size: number | null
          file_type: string
          file_url: string
          id: string
          project_id: string
        }
        Insert: {
          created_at?: string
          file_name: string
          file_size?: number | null
          file_type: string
          file_url: string
          id?: string
          project_id: string
        }
        Update: {
          created_at?: string
          file_name?: string
          file_size?: number | null
          file_type?: string
          file_url?: string
          id?: string
          project_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "project_attachments_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
        ]
      }
      project_details: {
        Row: {
          bonus_incentives: string | null
          category: string
          certifications: string[]
          collaboration_tools: string[]
          created_at: string
          currency: string
          current_team_size: string | null
          deadline_urgency: string | null
          engineers_needed: number
          estimated_duration: string | null
          existing_assets: string[]
          goals: string | null
          id: string
          milestones: Json
          payment_model: string | null
          payment_status: string
          preferred_skills: string[]
          problem: string | null
          project_id: string
          project_type: string
          required_skills: string[]
          responsibilities: Json
          roles_needed: string[]
          seniority_level: string | null
          stage: string
          tagline: string | null
          target_users: string | null
          tools_equipment: string[]
          updated_at: string
          weekly_commitment: string | null
          work_mode: string
          years_experience: number | null
        }
        Insert: {
          bonus_incentives?: string | null
          category?: string
          certifications?: string[]
          collaboration_tools?: string[]
          created_at?: string
          currency?: string
          current_team_size?: string | null
          deadline_urgency?: string | null
          engineers_needed?: number
          estimated_duration?: string | null
          existing_assets?: string[]
          goals?: string | null
          id?: string
          milestones?: Json
          payment_model?: string | null
          payment_status?: string
          preferred_skills?: string[]
          problem?: string | null
          project_id: string
          project_type?: string
          required_skills?: string[]
          responsibilities?: Json
          roles_needed?: string[]
          seniority_level?: string | null
          stage?: string
          tagline?: string | null
          target_users?: string | null
          tools_equipment?: string[]
          updated_at?: string
          weekly_commitment?: string | null
          work_mode?: string
          years_experience?: number | null
        }
        Update: {
          bonus_incentives?: string | null
          category?: string
          certifications?: string[]
          collaboration_tools?: string[]
          created_at?: string
          currency?: string
          current_team_size?: string | null
          deadline_urgency?: string | null
          engineers_needed?: number
          estimated_duration?: string | null
          existing_assets?: string[]
          goals?: string | null
          id?: string
          milestones?: Json
          payment_model?: string | null
          payment_status?: string
          preferred_skills?: string[]
          problem?: string | null
          project_id?: string
          project_type?: string
          required_skills?: string[]
          responsibilities?: Json
          roles_needed?: string[]
          seniority_level?: string | null
          stage?: string
          tagline?: string | null
          target_users?: string | null
          tools_equipment?: string[]
          updated_at?: string
          weekly_commitment?: string | null
          work_mode?: string
          years_experience?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "project_details_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: true
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
        ]
      }
      projects: {
        Row: {
          budget_max: number | null
          budget_min: number | null
          created_at: string
          description: string | null
          end_date: string | null
          governorate: string
          id: string
          image_url: string | null
          profile_id: string
          start_date: string | null
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          budget_max?: number | null
          budget_min?: number | null
          created_at?: string
          description?: string | null
          end_date?: string | null
          governorate: string
          id?: string
          image_url?: string | null
          profile_id: string
          start_date?: string | null
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          budget_max?: number | null
          budget_min?: number | null
          created_at?: string
          description?: string | null
          end_date?: string | null
          governorate?: string
          id?: string
          image_url?: string | null
          profile_id?: string
          start_date?: string | null
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "projects_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      rate_limits: {
        Row: {
          created_at: string
          id: string
          key: string
          request_count: number
          window_start: string
        }
        Insert: {
          created_at?: string
          id?: string
          key: string
          request_count?: number
          window_start?: string
        }
        Update: {
          created_at?: string
          id?: string
          key?: string
          request_count?: number
          window_start?: string
        }
        Relationships: []
      }
      reel_comments: {
        Row: {
          content: string
          created_at: string
          id: string
          likes_count: number | null
          parent_id: string | null
          profile_id: string
          reel_id: string
          updated_at: string
        }
        Insert: {
          content: string
          created_at?: string
          id?: string
          likes_count?: number | null
          parent_id?: string | null
          profile_id: string
          reel_id: string
          updated_at?: string
        }
        Update: {
          content?: string
          created_at?: string
          id?: string
          likes_count?: number | null
          parent_id?: string | null
          profile_id?: string
          reel_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "reel_comments_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "reel_comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reel_comments_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reel_comments_reel_id_fkey"
            columns: ["reel_id"]
            isOneToOne: false
            referencedRelation: "reels"
            referencedColumns: ["id"]
          },
        ]
      }
      reel_likes: {
        Row: {
          created_at: string
          id: string
          profile_id: string
          reel_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          profile_id: string
          reel_id: string
        }
        Update: {
          created_at?: string
          id?: string
          profile_id?: string
          reel_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reel_likes_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reel_likes_reel_id_fkey"
            columns: ["reel_id"]
            isOneToOne: false
            referencedRelation: "reels"
            referencedColumns: ["id"]
          },
        ]
      }
      reel_reports: {
        Row: {
          admin_notes: string | null
          created_at: string
          id: string
          reason: string
          reel_id: string
          reporter_id: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
        }
        Insert: {
          admin_notes?: string | null
          created_at?: string
          id?: string
          reason: string
          reel_id: string
          reporter_id: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          admin_notes?: string | null
          created_at?: string
          id?: string
          reason?: string
          reel_id?: string
          reporter_id?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "reel_reports_reel_id_fkey"
            columns: ["reel_id"]
            isOneToOne: false
            referencedRelation: "reels"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reel_reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reel_reports_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
      reel_views: {
        Row: {
          id: string
          reel_id: string
          viewed_at: string
          viewer_profile_id: string
        }
        Insert: {
          id?: string
          reel_id: string
          viewed_at?: string
          viewer_profile_id: string
        }
        Update: {
          id?: string
          reel_id?: string
          viewed_at?: string
          viewer_profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reel_views_reel_id_fkey"
            columns: ["reel_id"]
            isOneToOne: false
            referencedRelation: "reels"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reel_views_viewer_profile_id_fkey"
            columns: ["viewer_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reels: {
        Row: {
          caption: string | null
          comments_count: number | null
          created_at: string
          duration_seconds: number | null
          id: string
          is_active: boolean | null
          likes_count: number | null
          profile_id: string
          shares_count: number | null
          thumbnail_url: string | null
          updated_at: string
          video_url: string
          views_count: number | null
        }
        Insert: {
          caption?: string | null
          comments_count?: number | null
          created_at?: string
          duration_seconds?: number | null
          id?: string
          is_active?: boolean | null
          likes_count?: number | null
          profile_id: string
          shares_count?: number | null
          thumbnail_url?: string | null
          updated_at?: string
          video_url: string
          views_count?: number | null
        }
        Update: {
          caption?: string | null
          comments_count?: number | null
          created_at?: string
          duration_seconds?: number | null
          id?: string
          is_active?: boolean | null
          likes_count?: number | null
          profile_id?: string
          shares_count?: number | null
          thumbnail_url?: string | null
          updated_at?: string
          video_url?: string
          views_count?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "reels_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reviews: {
        Row: {
          comment: string | null
          created_at: string
          id: string
          rating: number
          reviewed_id: string
          reviewer_id: string
          updated_at: string
        }
        Insert: {
          comment?: string | null
          created_at?: string
          id?: string
          rating: number
          reviewed_id: string
          reviewer_id: string
          updated_at?: string
        }
        Update: {
          comment?: string | null
          created_at?: string
          id?: string
          rating?: number
          reviewed_id?: string
          reviewer_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "reviews_reviewed_id_fkey"
            columns: ["reviewed_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_reviewer_id_fkey"
            columns: ["reviewer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      role_permissions: {
        Row: {
          permission_id: string
          role_id: string
        }
        Insert: {
          permission_id: string
          role_id: string
        }
        Update: {
          permission_id?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "role_permissions_permission_id_fkey"
            columns: ["permission_id"]
            isOneToOne: false
            referencedRelation: "permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "role_permissions_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
      roles: {
        Row: {
          description: string | null
          id: string
          name: string
        }
        Insert: {
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      saved_items: {
        Row: {
          created_at: string
          detail: string | null
          id: string
          item_id: string
          item_type: string
          metadata: Json
          profile_id: string
          subtitle: string | null
          title: string
        }
        Insert: {
          created_at?: string
          detail?: string | null
          id?: string
          item_id: string
          item_type: string
          metadata?: Json
          profile_id: string
          subtitle?: string | null
          title: string
        }
        Update: {
          created_at?: string
          detail?: string | null
          id?: string
          item_id?: string
          item_type?: string
          metadata?: Json
          profile_id?: string
          subtitle?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "saved_items_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      saved_reels: {
        Row: {
          created_at: string
          id: string
          profile_id: string
          reel_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          profile_id: string
          reel_id: string
        }
        Update: {
          created_at?: string
          id?: string
          profile_id?: string
          reel_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "saved_reels_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "saved_reels_reel_id_fkey"
            columns: ["reel_id"]
            isOneToOne: false
            referencedRelation: "reels"
            referencedColumns: ["id"]
          },
        ]
      }
      storage_usage: {
        Row: {
          bucket_name: string
          created_at: string
          file_path: string
          file_size: number
          id: string
          mime_type: string | null
          profile_id: string
        }
        Insert: {
          bucket_name: string
          created_at?: string
          file_path: string
          file_size?: number
          id?: string
          mime_type?: string | null
          profile_id: string
        }
        Update: {
          bucket_name?: string
          created_at?: string
          file_path?: string
          file_size?: number
          id?: string
          mime_type?: string | null
          profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "storage_usage_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      stories: {
        Row: {
          archived_at: string | null
          content: string | null
          created_at: string
          expires_at: string
          id: string
          is_archived: boolean | null
          likes_count: number | null
          media_type: string
          media_url: string
          profile_id: string
          views_count: number | null
        }
        Insert: {
          archived_at?: string | null
          content?: string | null
          created_at?: string
          expires_at?: string
          id?: string
          is_archived?: boolean | null
          likes_count?: number | null
          media_type?: string
          media_url: string
          profile_id: string
          views_count?: number | null
        }
        Update: {
          archived_at?: string | null
          content?: string | null
          created_at?: string
          expires_at?: string
          id?: string
          is_archived?: boolean | null
          likes_count?: number | null
          media_type?: string
          media_url?: string
          profile_id?: string
          views_count?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "stories_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      story_comments: {
        Row: {
          content: string
          created_at: string
          id: string
          profile_id: string
          story_id: string
        }
        Insert: {
          content: string
          created_at?: string
          id?: string
          profile_id: string
          story_id: string
        }
        Update: {
          content?: string
          created_at?: string
          id?: string
          profile_id?: string
          story_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "story_comments_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "story_comments_story_id_fkey"
            columns: ["story_id"]
            isOneToOne: false
            referencedRelation: "stories"
            referencedColumns: ["id"]
          },
        ]
      }
      story_likes: {
        Row: {
          created_at: string
          id: string
          profile_id: string
          story_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          profile_id: string
          story_id: string
        }
        Update: {
          created_at?: string
          id?: string
          profile_id?: string
          story_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "story_likes_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "story_likes_story_id_fkey"
            columns: ["story_id"]
            isOneToOne: false
            referencedRelation: "stories"
            referencedColumns: ["id"]
          },
        ]
      }
      story_views: {
        Row: {
          id: string
          story_id: string
          viewed_at: string
          viewer_profile_id: string
        }
        Insert: {
          id?: string
          story_id: string
          viewed_at?: string
          viewer_profile_id: string
        }
        Update: {
          id?: string
          story_id?: string
          viewed_at?: string
          viewer_profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "story_views_story_id_fkey"
            columns: ["story_id"]
            isOneToOne: false
            referencedRelation: "stories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "story_views_viewer_profile_id_fkey"
            columns: ["viewer_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      subscriptions: {
        Row: {
          created_at: string
          expires_at: string | null
          id: string
          plan_type: string
          profile_id: string
          starts_at: string
          status: Database["public"]["Enums"]["subscription_status"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          expires_at?: string | null
          id?: string
          plan_type?: string
          profile_id: string
          starts_at?: string
          status?: Database["public"]["Enums"]["subscription_status"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          expires_at?: string | null
          id?: string
          plan_type?: string
          profile_id?: string
          starts_at?: string
          status?: Database["public"]["Enums"]["subscription_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      support_tickets: {
        Row: {
          admin_notes: string | null
          category: string
          created_at: string
          description: string
          id: string
          profile_id: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          subject: string
          updated_at: string
        }
        Insert: {
          admin_notes?: string | null
          category?: string
          created_at?: string
          description: string
          id?: string
          profile_id: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          subject: string
          updated_at?: string
        }
        Update: {
          admin_notes?: string | null
          category?: string
          created_at?: string
          description?: string
          id?: string
          profile_id?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          subject?: string
          updated_at?: string
        }
        Relationships: []
      }
      system_logs: {
        Row: {
          created_at: string | null
          id: string
          message: string | null
          metadata: Json | null
          type: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          message?: string | null
          metadata?: Json | null
          type?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          message?: string | null
          metadata?: Json | null
          type?: string | null
        }
        Relationships: []
      }
      system_status: {
        Row: {
          id: number
          service: string | null
          status: string | null
          updated_at: string | null
        }
        Insert: {
          id: number
          service?: string | null
          status?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: number
          service?: string | null
          status?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      user_reports: {
        Row: {
          admin_notes: string | null
          conversation_id: string | null
          created_at: string | null
          id: string
          reason: string | null
          reported_id: string
          reporter_id: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: string | null
          updated_at: string | null
        }
        Insert: {
          admin_notes?: string | null
          conversation_id?: string | null
          created_at?: string | null
          id?: string
          reason?: string | null
          reported_id: string
          reporter_id: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string | null
          updated_at?: string | null
        }
        Update: {
          admin_notes?: string | null
          conversation_id?: string | null
          created_at?: string | null
          id?: string
          reason?: string | null
          reported_id?: string
          reporter_id?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_reports_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_reports_reported_id_fkey"
            columns: ["reported_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_reports_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      activate_subscription_p: {
        Args: { p_profile_id: string }
        Returns: undefined
      }
      admin_has_permission: {
        Args: { p_permission_key: string }
        Returns: boolean
      }
      admin_has_role: {
        Args: { p_role: Database["public"]["Enums"]["admin_role"] }
        Returns: boolean
      }
      app_can_post_projects: {
        Args: { p_profile_id: string }
        Returns: boolean
      }
      app_current_profile_id: { Args: never; Returns: string }
      apply_to_project_for_app: {
        Args: {
          p_files?: Json
          p_message: string
          p_project_id: string
          p_subject: string
        }
        Returns: string
      }
      check_is_admin: { Args: { user_id: string }; Returns: boolean }
      check_permission: {
        Args: { p_permission: string; p_user_id: string }
        Returns: boolean
      }
      check_rate_limit: {
        Args: {
          p_key: string
          p_max_requests?: number
          p_window_minutes?: number
        }
        Returns: boolean
      }
      check_subscription_expiry_notifications: {
        Args: { p_profile_id: string }
        Returns: undefined
      }
      cleanup_expired_otps: { Args: never; Returns: undefined }
      cleanup_old_rate_limits: { Args: never; Returns: undefined }
      complete_signup_profile_for_app: {
        Args: {
          p_bio: string
          p_email: string
          p_full_name: string
          p_governorate: string
          p_phone: string
          p_role: string
        }
        Returns: string
      }
      create_notification: {
        Args: {
          p_action_url?: string
          p_message: string
          p_profile_id: string
          p_title: string
          p_type?: string
        }
        Returns: string
      }
      create_project_for_app: {
        Args: {
          p_bonus_incentives?: string
          p_budget_max?: number
          p_budget_min?: number
          p_category?: string
          p_certifications?: string[]
          p_collaboration_tools?: string[]
          p_currency?: string
          p_current_team_size?: string
          p_deadline_urgency?: string
          p_description: string
          p_engineers_needed?: number
          p_estimated_duration?: string
          p_existing_assets?: string[]
          p_goals?: string
          p_governorate: string
          p_milestones?: Json
          p_payment_model?: string
          p_payment_status?: string
          p_preferred_skills?: string[]
          p_problem?: string
          p_project_type?: string
          p_required_skills?: string[]
          p_responsibilities?: Json
          p_roles_needed?: string[]
          p_seniority_level?: string
          p_stage?: string
          p_tagline?: string
          p_target_users?: string
          p_title: string
          p_tools_equipment?: string[]
          p_weekly_commitment?: string
          p_work_mode?: string
          p_years_experience?: number
        }
        Returns: string
      }
      get_admin_chat_monitor: {
        Args: { p_limit?: number }
        Returns: {
          id: string
          last_message_at: string
          last_message_content: string
          participant_one_avatar: string
          participant_one_name: string
          participant_two_avatar: string
          participant_two_name: string
          updated_at: string
        }[]
      }
      get_admin_system_stats: { Args: never; Returns: Json }
      get_admin_user_id: { Args: never; Returns: string }
      get_conversation_participant_phone: {
        Args: { p_conversation_id: string; p_participant_id: string }
        Returns: string
      }
      get_home_feed: {
        Args: { p_limit?: number; p_offset?: number; p_profile_id: string }
        Returns: {
          avatar_url: string
          comments_count: number
          content: string
          created_at: string
          full_name: string
          image_url: string
          is_liked: boolean
          is_verified: boolean
          likes_count: number
          post_id: string
          post_type: string
          profile_id: string
          role: Database["public"]["Enums"]["user_role"]
          username: string
        }[]
      }
      get_network_profiles_for_app: {
        Args: { p_audience?: string; p_limit?: number }
        Returns: {
          avatar_url: string
          bio: string
          experience_years: number
          followers_count: number
          full_name: string
          governorate: string
          id: string
          is_verified: boolean
          projects_count: number
          role: string
          username: string
        }[]
      }
      get_profile_for_user: {
        Args: { p_profile_id: string }
        Returns: {
          avatar_url: string
          bio: string
          cover_photo_url: string
          created_at: string
          experience_years: number
          facebook_url: string
          followers_count: number
          following_count: number
          full_name: string
          governorate: Database["public"]["Enums"]["governorate"]
          id: string
          instagram_url: string
          is_verified: boolean
          phone: string
          posts_count: number
          projects_count: number
          rating: number
          role: Database["public"]["Enums"]["user_role"]
          total_reviews: number
          updated_at: string
          user_id: string
          username: string
        }[]
      }
      get_projects_for_app: {
        Args: { p_limit?: number }
        Returns: {
          budget_max: number
          budget_min: number
          created_at: string
          description: string
          end_date: string
          governorate: string
          id: string
          image_url: string
          profile_id: string
          profiles: Json
          project_details: Json
          start_date: string
          status: string
          title: string
        }[]
      }
      get_public_engineer_details: {
        Args: { p_profile_id: string }
        Returns: {
          company_name: string
          profile_id: string
          specialization: string
        }[]
      }
      get_public_profile: {
        Args: { p_profile_id: string }
        Returns: {
          avatar_url: string
          bio: string
          cover_photo_url: string
          created_at: string
          experience_years: number
          facebook_url: string
          followers_count: number
          following_count: number
          full_name: string
          governorate: Database["public"]["Enums"]["governorate"]
          id: string
          instagram_url: string
          is_verified: boolean
          posts_count: number
          projects_count: number
          rating: number
          role: Database["public"]["Enums"]["user_role"]
          total_reviews: number
          username: string
        }[]
      }
      get_public_profile_with_details: {
        Args: { p_profile_id: string }
        Returns: {
          avatar_url: string
          bio: string
          company_name: string
          cover_photo_url: string
          created_at: string
          experience_years: number
          facebook_url: string
          followers_count: number
          following_count: number
          full_name: string
          governorate: Database["public"]["Enums"]["governorate"]
          id: string
          instagram_url: string
          is_verified: boolean
          posts_count: number
          projects_count: number
          rating: number
          role: Database["public"]["Enums"]["user_role"]
          specialization: string
          total_reviews: number
          user_id: string
          username: string
        }[]
      }
      get_public_profiles: {
        Args: { p_profile_ids: string[] }
        Returns: {
          avatar_url: string
          full_name: string
          id: string
          is_verified: boolean
          role: Database["public"]["Enums"]["user_role"]
          username: string
        }[]
      }
      get_safe_profile: {
        Args: { p_profile_id: string }
        Returns: {
          avatar_url: string
          bio: string
          cover_photo_url: string
          created_at: string
          experience_years: number
          facebook_url: string
          followers_count: number
          following_count: number
          full_name: string
          governorate: Database["public"]["Enums"]["governorate"]
          id: string
          instagram_url: string
          is_verified: boolean
          phone: string
          posts_count: number
          projects_count: number
          rating: number
          role: Database["public"]["Enums"]["user_role"]
          total_reviews: number
          updated_at: string
          user_id: string
          username: string
        }[]
      }
      get_storage_overview: {
        Args: never
        Returns: {
          bucket_name: string
          formatted_size: string
          total_files: number
          total_size: number
          unique_users: number
        }[]
      }
      get_suspicious_users: {
        Args: { min_attempts?: number; time_window?: string }
        Returns: {
          attempt_count: number
          attempt_types: string[]
          full_name: string
          last_attempt: string
          profile_id: string
        }[]
      }
      get_unread_messages_count: {
        Args: { p_profile_id: string }
        Returns: number
      }
      get_user_conversations: {
        Args: { p_profile_id: string }
        Returns: {
          conversation_id: string
          is_muted: boolean
          last_message: string
          last_message_at: string
          recipient_avatar: string
          recipient_id: string
          recipient_name: string
          unread_count: number
        }[]
      }
      get_user_storage_stats: {
        Args: { p_profile_id: string }
        Returns: {
          bucket_name: string
          file_count: number
          formatted_size: string
          total_size: number
        }[]
      }
      has_active_subscription: {
        Args: { p_profile_id: string }
        Returns: boolean
      }
      increment_reel_view:
        | { Args: { p_reel_id: string }; Returns: undefined }
        | {
            Args: { p_reel_id: string; p_viewer_profile_id?: string }
            Returns: undefined
          }
      increment_story_view: {
        Args: { p_story_id: string; p_viewer_profile_id: string }
        Returns: undefined
      }
      is_admin: { Args: never; Returns: boolean }
      is_blocked: {
        Args: { checker_id: string; target_id: string }
        Returns: boolean
      }
      is_own_profile: { Args: { profile_user_id: string }; Returns: boolean }
      is_profile_owner: { Args: { profile_user_id: string }; Returns: boolean }
      is_super_admin: { Args: never; Returns: boolean }
      log_admin_action:
        | {
            Args: {
              p_action: string
              p_entity?: string
              p_entity_id?: string
              p_new?: Json
              p_old?: Json
            }
            Returns: undefined
          }
        | {
            Args: {
              p_action: string
              p_entity: string
              p_entity_id?: string
              p_metadata?: Json
              p_new_values?: Json
              p_old_values?: Json
            }
            Returns: string
          }
      mark_messages_read: {
        Args: { p_conversation_id: string; p_reader_profile_id: string }
        Returns: undefined
      }
      request_connection_for_app: {
        Args: { p_message?: string; p_receiver_profile_id: string }
        Returns: string
      }
      save_item_for_app: {
        Args: {
          p_detail?: string
          p_item_id: string
          p_item_type: string
          p_metadata?: Json
          p_subtitle?: string
          p_title: string
        }
        Returns: string
      }
      search_profiles_safe: {
        Args: {
          p_governorate?: Database["public"]["Enums"]["governorate"]
          p_limit?: number
          p_offset?: number
          p_role?: Database["public"]["Enums"]["user_role"]
          p_search_term?: string
        }
        Returns: {
          avatar_url: string
          bio: string
          experience_years: number
          followers_count: number
          following_count: number
          full_name: string
          governorate: Database["public"]["Enums"]["governorate"]
          id: string
          is_verified: boolean
          rating: number
          role: Database["public"]["Enums"]["user_role"]
          total_reviews: number
          username: string
        }[]
      }
      show_limit: { Args: never; Returns: number }
      show_trgm: { Args: { "": string }; Returns: string[] }
      toggle_story_like: {
        Args: { p_profile_id: string; p_story_id: string }
        Returns: boolean
      }
      verify_otp_token: {
        Args: { p_phone_local10: string; p_verification_token: string }
        Returns: boolean
      }
    }
    Enums: {
      admin_role:
        | "super_admin"
        | "admin"
        | "content_manager"
        | "instructor"
        | "support"
        | "viewer"
      admin_status: "active" | "suspended" | "pending"
      asset_type:
        | "video"
        | "pdf"
        | "image"
        | "audio"
        | "document"
        | "presentation"
        | "other"
      contractor_status: "working" | "available"
      course_category: "theoretical" | "practical" | "training"
      craftsman_specialization:
        | "plastering"
        | "carpentry"
        | "blacksmith"
        | "painter"
        | "plumber"
        | "electrician"
        | "tiling"
        | "other"
        | "mechanic"
        | "hvac"
        | "aluminum"
        | "solar"
        | "cameras"
        | "brick_mason"
        | "concrete_worker"
      engineer_specialization:
        | "architectural"
        | "civil"
        | "electrical"
        | "mechanical"
        | "chemical"
        | "environmental"
        | "petroleum"
        | "other"
        | "computer"
        | "surveying"
      governorate:
        | "baghdad"
        | "basra"
        | "nineveh"
        | "erbil"
        | "sulaymaniyah"
        | "duhok"
        | "kirkuk"
        | "diyala"
        | "anbar"
        | "babylon"
        | "karbala"
        | "najaf"
        | "wasit"
        | "saladin"
        | "dhi_qar"
        | "maysan"
        | "muthanna"
        | "qadisiyah"
      lecture_status: "draft" | "pending_review" | "published" | "archived"
      machinery_specialization:
        | "excavator"
        | "crane"
        | "loader"
        | "bulldozer"
        | "forklift"
        | "concrete_mixer"
        | "truck"
        | "tanker"
        | "generator"
        | "compressor"
        | "other"
        | "tuk_tuk"
      notification_target_type: "all" | "role" | "department" | "user"
      subscription_status: "active" | "expired" | "cancelled" | "trial"
      user_role:
        | "engineer"
        | "contractor"
        | "craftsman"
        | "client"
        | "worker"
        | "machinery"
        | "admin"
        | "moderator"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  storage: {
    Tables: {
      buckets: {
        Row: {
          allowed_mime_types: string[] | null
          avif_autodetection: boolean | null
          created_at: string | null
          file_size_limit: number | null
          id: string
          name: string
          owner: string | null
          owner_id: string | null
          public: boolean | null
          type: Database["storage"]["Enums"]["buckettype"]
          updated_at: string | null
        }
        Insert: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id: string
          name: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string | null
        }
        Update: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id?: string
          name?: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string | null
        }
        Relationships: []
      }
      buckets_analytics: {
        Row: {
          created_at: string
          deleted_at: string | null
          format: string
          id: string
          name: string
          type: Database["storage"]["Enums"]["buckettype"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          format?: string
          id?: string
          name: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          format?: string
          id?: string
          name?: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Relationships: []
      }
      buckets_vectors: {
        Row: {
          created_at: string
          id: string
          type: Database["storage"]["Enums"]["buckettype"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          id: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Relationships: []
      }
      migrations: {
        Row: {
          executed_at: string | null
          hash: string
          id: number
          name: string
        }
        Insert: {
          executed_at?: string | null
          hash: string
          id: number
          name: string
        }
        Update: {
          executed_at?: string | null
          hash?: string
          id?: number
          name?: string
        }
        Relationships: []
      }
      objects: {
        Row: {
          bucket_id: string | null
          created_at: string | null
          id: string
          last_accessed_at: string | null
          metadata: Json | null
          name: string | null
          owner: string | null
          owner_id: string | null
          path_tokens: string[] | null
          updated_at: string | null
          user_metadata: Json | null
          version: string | null
        }
        Insert: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          user_metadata?: Json | null
          version?: string | null
        }
        Update: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          user_metadata?: Json | null
          version?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "objects_bucketId_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
        ]
      }
      s3_multipart_uploads: {
        Row: {
          bucket_id: string
          created_at: string
          id: string
          in_progress_size: number
          key: string
          metadata: Json | null
          owner_id: string | null
          upload_signature: string
          user_metadata: Json | null
          version: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          id: string
          in_progress_size?: number
          key: string
          metadata?: Json | null
          owner_id?: string | null
          upload_signature: string
          user_metadata?: Json | null
          version: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          id?: string
          in_progress_size?: number
          key?: string
          metadata?: Json | null
          owner_id?: string | null
          upload_signature?: string
          user_metadata?: Json | null
          version?: string
        }
        Relationships: [
          {
            foreignKeyName: "s3_multipart_uploads_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
        ]
      }
      s3_multipart_uploads_parts: {
        Row: {
          bucket_id: string
          created_at: string
          etag: string
          id: string
          key: string
          owner_id: string | null
          part_number: number
          size: number
          upload_id: string
          version: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          etag: string
          id?: string
          key: string
          owner_id?: string | null
          part_number: number
          size?: number
          upload_id: string
          version: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          etag?: string
          id?: string
          key?: string
          owner_id?: string | null
          part_number?: number
          size?: number
          upload_id?: string
          version?: string
        }
        Relationships: [
          {
            foreignKeyName: "s3_multipart_uploads_parts_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "s3_multipart_uploads_parts_upload_id_fkey"
            columns: ["upload_id"]
            isOneToOne: false
            referencedRelation: "s3_multipart_uploads"
            referencedColumns: ["id"]
          },
        ]
      }
      vector_indexes: {
        Row: {
          bucket_id: string
          created_at: string
          data_type: string
          dimension: number
          distance_metric: string
          id: string
          metadata_configuration: Json | null
          name: string
          updated_at: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          data_type: string
          dimension: number
          distance_metric: string
          id?: string
          metadata_configuration?: Json | null
          name: string
          updated_at?: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          data_type?: string
          dimension?: number
          distance_metric?: string
          id?: string
          metadata_configuration?: Json | null
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vector_indexes_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets_vectors"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      allow_any_operation: {
        Args: { expected_operations: string[] }
        Returns: boolean
      }
      allow_only_operation: {
        Args: { expected_operation: string }
        Returns: boolean
      }
      can_insert_object: {
        Args: { bucketid: string; metadata: Json; name: string; owner: string }
        Returns: undefined
      }
      extension: { Args: { name: string }; Returns: string }
      filename: { Args: { name: string }; Returns: string }
      foldername: { Args: { name: string }; Returns: string[] }
      get_common_prefix: {
        Args: { p_delimiter: string; p_key: string; p_prefix: string }
        Returns: string
      }
      get_size_by_bucket: {
        Args: never
        Returns: {
          bucket_id: string
          size: number
        }[]
      }
      list_multipart_uploads_with_delimiter: {
        Args: {
          bucket_id: string
          delimiter_param: string
          max_keys?: number
          next_key_token?: string
          next_upload_token?: string
          prefix_param: string
        }
        Returns: {
          created_at: string
          id: string
          key: string
        }[]
      }
      list_objects_with_delimiter: {
        Args: {
          _bucket_id: string
          delimiter_param: string
          max_keys?: number
          next_token?: string
          prefix_param: string
          sort_order?: string
          start_after?: string
        }
        Returns: {
          created_at: string
          id: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      operation: { Args: never; Returns: string }
      search: {
        Args: {
          bucketname: string
          levels?: number
          limits?: number
          offsets?: number
          prefix: string
          search?: string
          sortcolumn?: string
          sortorder?: string
        }
        Returns: {
          created_at: string
          id: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      search_by_timestamp: {
        Args: {
          p_bucket_id: string
          p_level: number
          p_limit: number
          p_prefix: string
          p_sort_column: string
          p_sort_column_after: string
          p_sort_order: string
          p_start_after: string
        }
        Returns: {
          created_at: string
          id: string
          key: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      search_v2: {
        Args: {
          bucket_name: string
          levels?: number
          limits?: number
          prefix: string
          sort_column?: string
          sort_column_after?: string
          sort_order?: string
          start_after?: string
        }
        Returns: {
          created_at: string
          id: string
          key: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
    }
    Enums: {
      buckettype: "STANDARD" | "ANALYTICS" | "VECTOR"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      admin_role: [
        "super_admin",
        "admin",
        "content_manager",
        "instructor",
        "support",
        "viewer",
      ],
      admin_status: ["active", "suspended", "pending"],
      asset_type: [
        "video",
        "pdf",
        "image",
        "audio",
        "document",
        "presentation",
        "other",
      ],
      contractor_status: ["working", "available"],
      course_category: ["theoretical", "practical", "training"],
      craftsman_specialization: [
        "plastering",
        "carpentry",
        "blacksmith",
        "painter",
        "plumber",
        "electrician",
        "tiling",
        "other",
        "mechanic",
        "hvac",
        "aluminum",
        "solar",
        "cameras",
        "brick_mason",
        "concrete_worker",
      ],
      engineer_specialization: [
        "architectural",
        "civil",
        "electrical",
        "mechanical",
        "chemical",
        "environmental",
        "petroleum",
        "other",
        "computer",
        "surveying",
      ],
      governorate: [
        "baghdad",
        "basra",
        "nineveh",
        "erbil",
        "sulaymaniyah",
        "duhok",
        "kirkuk",
        "diyala",
        "anbar",
        "babylon",
        "karbala",
        "najaf",
        "wasit",
        "saladin",
        "dhi_qar",
        "maysan",
        "muthanna",
        "qadisiyah",
      ],
      lecture_status: ["draft", "pending_review", "published", "archived"],
      machinery_specialization: [
        "excavator",
        "crane",
        "loader",
        "bulldozer",
        "forklift",
        "concrete_mixer",
        "truck",
        "tanker",
        "generator",
        "compressor",
        "other",
        "tuk_tuk",
      ],
      notification_target_type: ["all", "role", "department", "user"],
      subscription_status: ["active", "expired", "cancelled", "trial"],
      user_role: [
        "engineer",
        "contractor",
        "craftsman",
        "client",
        "worker",
        "machinery",
        "admin",
        "moderator",
      ],
    },
  },
  storage: {
    Enums: {
      buckettype: ["STANDARD", "ANALYTICS", "VECTOR"],
    },
  },
} as const
