export type ProfileSection = {
  id: number
  key: string
  title: string
  markdown_body: string
  position: number
}

export type BlogPost = {
  id: number
  title: string
  slug: string
  summary: string | null
  markdown_body?: string
  status: string
  published_at: string | null
  scheduled_for?: string | null
  tag_names?: string[]
  tags?: Array<{ id: number; name: string; slug: string }>
}

export type AvailabilitySlot = {
  start_at: string
  end_at: string
}

export type AvailabilityDay = {
  date: string
  slots: AvailabilitySlot[]
}

export type SiteContent = {
  hero_photo_url: string | null
  resume_url: string | null
  resume_text?: string | null
}

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000'

type RequestOptions = RequestInit & {
  token?: string | null
}

async function apiRequest<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const headers = new Headers(options.headers ?? {})
  headers.set('Content-Type', 'application/json')
  if (options.token) headers.set('Authorization', `Bearer ${options.token}`)

  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
  })

  if (!response.ok) {
    const fallback = `Request failed (${response.status})`
    try {
      const payload = (await response.json()) as { error?: string; errors?: string[] }
      throw new Error(payload.error ?? payload.errors?.join(', ') ?? fallback)
    } catch {
      throw new Error(fallback)
    }
  }

  if (response.status === 204) return null as T
  return (await response.json()) as T
}

export const publicApi = {
  getSiteContent: () => apiRequest<SiteContent>('/api/v1/public/site_content'),
  getProfileSections: () => apiRequest<ProfileSection[]>('/api/v1/public/profile_sections'),
  getBlogPosts: () => apiRequest<BlogPost[]>('/api/v1/public/blog_posts'),
  getBlogPost: (slug: string) => apiRequest<BlogPost>(`/api/v1/public/blog_posts/${slug}`),
  getAvailability: (timezone: string) =>
    apiRequest<{ timezone: string; days: AvailabilityDay[]; slots: AvailabilitySlot[] }>(
      `/api/v1/public/availability?timezone=${encodeURIComponent(timezone)}&days=14`,
    ),
  createMeeting: (payload: {
    name: string
    email: string
    timezone: string
    start_at: string
    end_at: string
    topic: string
    notes: string
  }) =>
    apiRequest('/api/v1/public/meetings', {
      method: 'POST',
      body: JSON.stringify({ meeting: payload }),
    }),
  createContact: (payload: { name: string; email: string; company: string; message: string }) =>
    apiRequest('/api/v1/public/contacts', {
      method: 'POST',
      body: JSON.stringify({ contact: payload }),
    }),
}

export const adminApi = {
  login: (email: string, password: string) =>
    apiRequest<{ token: string; user: { id: number; email: string; name: string; role: string } }>(
      '/api/v1/admin/session',
      {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      },
    ),
  getPosts: (token: string) => apiRequest<BlogPost[]>('/api/v1/admin/blog_posts', { token }),
  savePost: (token: string, payload: Partial<BlogPost>) => {
    const hasId = typeof payload.id === 'number' && payload.id > 0
    return apiRequest<BlogPost>(`/api/v1/admin/blog_posts${hasId ? `/${payload.id}` : ''}`, {
      method: hasId ? 'PATCH' : 'POST',
      token,
      body: JSON.stringify({
        blog_post: {
          title: payload.title ?? '',
          slug: payload.slug ?? '',
          summary: payload.summary ?? '',
          markdown_body: payload.markdown_body ?? '',
          status: payload.status ?? 'draft',
          scheduled_for: payload.scheduled_for ?? null,
          tag_names: payload.tag_names ?? [],
        },
      }),
    })
  },
  deletePost: (token: string, id: number) =>
    apiRequest<void>(`/api/v1/admin/blog_posts/${id}`, { method: 'DELETE', token }),
  getIntegrations: (token: string) =>
    apiRequest<{
      integrations: Array<{
        provider: string
        active: boolean
        external_account_id: string | null
        expires_at: string | null
        expired: boolean
      }>
    }>('/api/v1/admin/integrations/status', { token }),
  exchangeGoogleCode: (token: string, code: string, redirectUri: string) =>
    apiRequest('/api/v1/admin/integrations/google_exchange', {
      method: 'POST',
      token,
      body: JSON.stringify({ code, redirect_uri: redirectUri }),
    }),
  exchangeZoomCode: (token: string, code: string, redirectUri: string) =>
    apiRequest('/api/v1/admin/integrations/zoom_exchange', {
      method: 'POST',
      token,
      body: JSON.stringify({ code, redirect_uri: redirectUri }),
    }),
  getSiteContent: (token: string) => apiRequest<SiteContent>('/api/v1/admin/site_content', { token }),
  uploadHeroPhoto: async (token: string, file: File) => {
    const formData = new FormData()
    formData.append('image', file)
    const response = await fetch(`${API_BASE}/api/v1/admin/site_content/hero_photo`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: formData,
    })

    if (!response.ok) {
      const fallback = `Upload failed (${response.status})`
      try {
        const payload = (await response.json()) as { error?: string }
        throw new Error(payload.error ?? fallback)
      } catch {
        throw new Error(fallback)
      }
    }

    return (await response.json()) as SiteContent
  },
  removeHeroPhoto: (token: string) =>
    apiRequest<void>('/api/v1/admin/site_content/hero_photo', { method: 'DELETE', token }),
  uploadResume: async (token: string, file: File) => {
    const formData = new FormData()
    formData.append('file', file)
    const response = await fetch(`${API_BASE}/api/v1/admin/site_content/resume`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: formData,
    })

    if (!response.ok) {
      const fallback = `Upload failed (${response.status})`
      try {
        const payload = (await response.json()) as { error?: string }
        throw new Error(payload.error ?? fallback)
      } catch {
        throw new Error(fallback)
      }
    }

    return (await response.json()) as SiteContent
  },
  removeResume: (token: string) =>
    apiRequest<void>('/api/v1/admin/site_content/resume', { method: 'DELETE', token }),
}
