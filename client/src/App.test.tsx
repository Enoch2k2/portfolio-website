import { render, screen, waitFor } from '@testing-library/react'
import App from './App'

type MockJson = Record<string, unknown> | Array<Record<string, unknown>>

function responseFor(url: string): MockJson {
  if (url.includes('/api/v1/public/site_content')) {
    return { hero_photo_url: null, resume_url: null }
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
  if (url.includes('/api/v1/public/availability')) {
    return { timezone: 'UTC', days: [], slots: [] }
  }

  return {}
}

beforeEach(() => {
  vi.stubGlobal(
    'fetch',
    vi.fn(async (input: RequestInfo | URL) => {
      const url = String(input)
      return new Response(JSON.stringify(responseFor(url)), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }),
  )
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
})
