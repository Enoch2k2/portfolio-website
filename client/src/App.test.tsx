import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import App from './App'

type MockJson = Record<string, unknown> | Array<Record<string, unknown>>
type ResponseOverrides = {
  publicSiteContent?: MockJson
}

function responseFor(url: string, overrides: ResponseOverrides = {}): MockJson {
  if (url.includes('/api/v1/public/site_content')) {
    return overrides.publicSiteContent ?? { hero_photo_url: null, resume_url: null }
  }
  if (url.includes('/api/v1/public/blog_posts?')) {
    return []
  }
  if (url.includes('/api/v1/public/blog_posts')) {
    return [
      {
        id: 1,
        title: 'Test Blog Post',
        slug: 'test-blog-post',
        summary: 'Test summary',
        status: 'published',
        published_at: '2026-02-18T10:00:00Z',
        tag_names: ['test'],
      },
    ]
  }
  if (url.includes('/api/v1/public/profile_sections')) {
    return []
  }
  if (url.includes('/api/v1/admin/blog_posts')) {
    return [
      {
        id: 1,
        title: 'Admin Post',
        slug: 'admin-post',
        summary: 'Admin summary',
        markdown_body: '# Body',
        status: 'draft',
        published_at: null,
        scheduled_for: null,
        tag_names: [],
      },
    ]
  }
  if (url.includes('/api/v1/admin/integrations/status')) {
    return { integrations: [] }
  }
  if (url.includes('/api/v1/admin/site_content')) {
    return { hero_photo_url: null, resume_url: null }
  }
  if (url.includes('/api/v1/public/availability')) {
    return {
      timezone: 'UTC',
      days: [
        {
          date: '2026-02-20',
          slots: [{ start_at: '2026-02-20T15:00:00Z', end_at: '2026-02-20T15:30:00Z' }],
        },
      ],
      slots: [{ start_at: '2026-02-20T15:00:00Z', end_at: '2026-02-20T15:30:00Z' }],
    }
  }
  if (url.endsWith('/api/v1/public/meetings')) {
    return {
      id: 42,
      name: 'Test User',
      email: 'test@example.com',
      timezone: 'UTC',
      start_at: '2026-02-20T15:00:00Z',
      end_at: '2026-02-20T15:30:00Z',
      status: 'tentative',
      topic: 'Website Consultation',
      notes: '',
      zoom_join_url: null,
      google_event_id: null,
      created_at: '2026-02-18T10:00:00Z',
      updated_at: '2026-02-18T10:00:00Z',
    }
  }
  if (url.includes('/api/v1/public/meetings/')) {
    return {
      id: 42,
      name: 'Test User',
      email: 'test@example.com',
      timezone: 'UTC',
      start_at: '2026-02-20T15:00:00Z',
      end_at: '2026-02-20T15:30:00Z',
      status: 'scheduled',
      topic: 'Website Consultation',
      notes: '',
      zoom_join_url: 'https://zoom.us/j/42',
      google_event_id: 'google-42',
      created_at: '2026-02-18T10:00:00Z',
      updated_at: '2026-02-18T10:00:00Z',
    }
  }

  return {}
}

function installFetchMock(overrides: ResponseOverrides = {}) {
  vi.stubGlobal(
    'fetch',
    vi.fn(async (input: RequestInfo | URL) => {
      const url = String(input)
      return new Response(JSON.stringify(responseFor(url, overrides)), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }),
  )
}

beforeEach(() => {
  installFetchMock()
  window.localStorage.clear()
})

afterEach(() => {
  vi.restoreAllMocks()
})

describe('App', () => {
  it('renders homepage headline and primary navigation', async () => {
    window.history.replaceState({}, '', '/')
    render(<App />)

    expect(await screen.findByText(/Strategic digital products and websites/i)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Home' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Blog' })).toBeInTheDocument()
  })

  it('renders blog posts on blog route', async () => {
    window.history.replaceState({}, '', '/blog')
    render(<App />)

    await waitFor(() => {
      expect(screen.getByText('Test Blog Post')).toBeInTheDocument()
    })
    expect(screen.getByText('Test summary')).toBeInTheDocument()
  })

  it('shows admin tabs and allows switching between sections', async () => {
    window.localStorage.setItem('adminToken', 'test-token')
    window.history.replaceState({}, '', '/workspace-ops')
    render(<App />)

    expect(await screen.findByRole('button', { name: 'Profile' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Integrations' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Blog' })).toBeInTheDocument()
    expect(screen.getByText('Landing Photo')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Integrations' }))
    expect(await screen.findByText('Calendar Availability')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Blog' }))
    expect(await screen.findByRole('button', { name: 'Create New Blog' })).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'View Blogs' }))
    expect(await screen.findByRole('button', { name: /Admin Post/i })).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Profile' }))
    expect(await screen.findByText('Resume (PDF)')).toBeInTheDocument()
    expect(screen.getByText(/Drag and drop your PDF resume here/i)).toBeInTheDocument()
  })

  it('renders inline resume viewer on resume route when resume url exists', async () => {
    installFetchMock({
      publicSiteContent: {
        hero_photo_url: null,
        resume_url: 'https://example.com/resume.pdf',
        resume_text: 'Senior Developer\n\nBuilt scalable products.',
      },
    })
    window.history.replaceState({}, '', '/resume')
    render(<App />)

    expect(await screen.findByRole('link', { name: 'Open Resume PDF' })).toBeInTheDocument()
    expect(await screen.findByText(/Senior Developer/i)).toBeInTheDocument()
    expect(screen.getByText(/Built scalable products\./i)).toBeInTheDocument()
  })

  it('submits booking then shows meeting provisioning success details', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
        const url = String(input)
        const method = init?.method ?? 'GET'

        if (url.includes('/api/v1/public/meetings/42') && method === 'GET') {
          const payload = {
            id: 42,
            name: 'Test User',
            email: 'test@example.com',
            timezone: 'UTC',
            start_at: '2026-02-20T15:00:00Z',
            end_at: '2026-02-20T15:30:00Z',
            status: 'scheduled',
            topic: 'Website Consultation',
            notes: '',
            zoom_join_url: 'https://zoom.us/j/42',
            google_event_id: 'google-42',
            created_at: '2026-02-18T10:00:00Z',
            updated_at: '2026-02-18T10:00:00Z',
          }
          return new Response(JSON.stringify(payload), { status: 200, headers: { 'Content-Type': 'application/json' } })
        }

        return new Response(JSON.stringify(responseFor(url)), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        })
      }),
    )

    window.history.replaceState({}, '', '/book')
    render(<App />)

    const slotLabel = new Date('2026-02-20T15:00:00Z').toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })
    fireEvent.click(await screen.findByRole('button', { name: slotLabel }))
    fireEvent.change(screen.getByLabelText('Name'), { target: { value: 'Test User' } })
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'test@example.com' } })
    fireEvent.click(screen.getByRole('button', { name: 'Request Meeting' }))

    expect(await screen.findByText('Creating your meeting')).toBeInTheDocument()
    expect(await screen.findByText('Your meeting has been created.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'https://zoom.us/j/42' })).toBeInTheDocument()
  })

  it('routes to oops page when meeting provisioning reports failed', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: RequestInfo | URL) => {
        const url = String(input)

        if (url.includes('/api/v1/public/meetings/42')) {
          return new Response(
            JSON.stringify({
              id: 42,
              name: 'Test User',
              email: 'test@example.com',
              timezone: 'UTC',
              start_at: '2026-02-20T15:00:00Z',
              end_at: '2026-02-20T15:30:00Z',
              status: 'failed',
              topic: 'Website Consultation',
              notes: 'Provisioning error',
              zoom_join_url: null,
              google_event_id: null,
              created_at: '2026-02-18T10:00:00Z',
              updated_at: '2026-02-18T10:00:00Z',
            }),
            { status: 200, headers: { 'Content-Type': 'application/json' } },
          )
        }

        return new Response(JSON.stringify(responseFor(url)), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        })
      }),
    )

    window.history.replaceState({}, '', '/book/status/42')
    render(<App />)

    expect(await screen.findByText(/Oops, we hit an unexpected error/i)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Try again' })).toBeInTheDocument()
  })
})
