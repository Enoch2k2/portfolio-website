import { useEffect, useMemo, useState } from 'react'
import type { DragEvent, FormEvent } from 'react'
import { BrowserRouter, Link, NavLink, Route, Routes, useLocation, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { MarkdownContent } from './components/MarkdownContent'
import { adminApi, publicApi } from './lib/api'
import type { AvailabilityDay, BlogPost, SiteContent } from './lib/api'

const ADMIN_PATH = import.meta.env.VITE_ADMIN_PATH ?? '/workspace-ops'
const GOOGLE_CALLBACK_PATH = import.meta.env.VITE_GOOGLE_OAUTH_REDIRECT_PATH ?? '/oauth/google/callback'
const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID ?? ''
const GOOGLE_OAUTH_SCOPE = 'https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/calendar.freebusy'
const ZOOM_CALLBACK_PATH = import.meta.env.VITE_ZOOM_OAUTH_REDIRECT_PATH ?? '/oauth/zoom/callback'
const ZOOM_CLIENT_ID = import.meta.env.VITE_ZOOM_CLIENT_ID ?? ''
const ZOOM_REDIRECT_URI_OVERRIDE = import.meta.env.VITE_ZOOM_OAUTH_REDIRECT_URI ?? ''

function zoomRedirectUri() {
  return ZOOM_REDIRECT_URI_OVERRIDE || `${window.location.origin}${ZOOM_CALLBACK_PATH}`
}

function useRevealOnScroll(selector: string, rerunKey = 0) {
  useEffect(() => {
    const items = Array.from(document.querySelectorAll<HTMLElement>(selector))
    if (items.length === 0) return

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return
          entry.target.classList.add('is-visible')
          observer.unobserve(entry.target)
        })
      },
      { threshold: 0.15, rootMargin: '0px 0px -8% 0px' },
    )

    items.forEach((item, index) => {
      item.style.transitionDelay = `${index * 70}ms`
      observer.observe(item)
    })

    return () => observer.disconnect()
  }, [selector, rerunKey])
}

function App() {
  return (
    <BrowserRouter>
      <div className="app-shell">
        <header className="site-header">
          <div className="container nav-wrap">
            <Link to="/" className="logo-text">
              Griffith Dev
            </Link>
            <nav className="nav-links">
              <NavLink to="/">Home</NavLink>
              <NavLink to="/services">Services</NavLink>
              <NavLink to="/portfolio">Portfolio</NavLink>
              <NavLink to="/resume">Resume</NavLink>
              <NavLink to="/blog">Blog</NavLink>
              <NavLink to="/book">Book a Call</NavLink>
            </nav>
          </div>
        </header>

        <main className="container">
          <AnimatedRoutes />
        </main>
      </div>
    </BrowserRouter>
  )
}

function AnimatedRoutes() {
  const location = useLocation()

  return (
    <div key={location.pathname} className="route-transition">
      <Routes location={location}>
        <Route path="/" element={<HomePage />} />
        <Route path="/services" element={<ServicesPage />} />
        <Route path="/portfolio" element={<PortfolioPage />} />
        <Route path="/resume" element={<ResumePage />} />
        <Route path="/blog" element={<BlogListPage />} />
        <Route path="/blog/:slug" element={<BlogDetailPage />} />
        <Route path="/book" element={<BookingPage />} />
        <Route path={GOOGLE_CALLBACK_PATH} element={<GoogleOauthCallbackPage />} />
        <Route path={ZOOM_CALLBACK_PATH} element={<ZoomOauthCallbackPage />} />
        <Route path={ADMIN_PATH} element={<AdminPage />} />
      </Routes>
    </div>
  )
}

function HomePage() {
  const [siteContent, setSiteContent] = useState<SiteContent>({ hero_photo_url: null, resume_url: null })

  useEffect(() => {
    publicApi
      .getSiteContent()
      .then((data) => setSiteContent(data))
      .catch(() => setSiteContent({ hero_photo_url: null, resume_url: null }))
  }, [])
  useRevealOnScroll('.home-flow .reveal-on-scroll')

  return (
    <section className="stack-xl home-flow">
      <div className="hero-card hero-layout">
        <div className="stack-md hero-content">
          <p className="eyebrow">Independent Product & Web Consultant</p>
          <h1>Strategic digital products and websites built to strengthen credibility and drive measurable growth.</h1>
          <p className="lead">
            I work with founders and teams to translate business goals into polished, dependable digital
            experiences that perform under real-world demands.
          </p>
          <div className="button-row">
            <Link className="btn btn-primary" to="/book">
              Book a Website Consultation
            </Link>
            <Link className="btn btn-ghost" to="/portfolio">
              View Case Studies
            </Link>
          </div>
          <p className="status">Senior-level delivery, clear accountability, and consistent execution.</p>
          <p>
            Engagements typically include product strategy, conversion-focused web delivery, technical
            modernization, and ongoing optimization.
          </p>
        </div>
        <div className="hero-photo-wrap">
          {siteContent.hero_photo_url ? (
            <img src={siteContent.hero_photo_url} alt="Portrait" className="hero-photo" />
          ) : (
            <div className="hero-photo hero-photo-placeholder">Add your photo in Admin</div>
          )}
        </div>
      </div>

      <div className="bento-grid">
        <article className="card bento-card bento-card-wide reveal-on-scroll">
          <div className="bento-head">
            <span className="bento-icon">01</span>
            <span className="bento-chip">Delivery</span>
          </div>
          <p className="eyebrow">How I Work</p>
          <h3>Structured delivery from strategy through execution.</h3>
          <p>Clear milestones, focused weekly updates, and decisions grounded in measurable outcomes.</p>
        </article>
        <article className="card bento-card reveal-on-scroll">
          <div className="bento-head">
            <span className="bento-icon">02</span>
            <span className="bento-chip">Velocity</span>
          </div>
          <p className="eyebrow">Speed</p>
          <h3>Fast iteration cycles</h3>
          <p>Lean scope, high-quality shipping, and predictable momentum.</p>
        </article>
        <article className="card bento-card reveal-on-scroll">
          <div className="bento-head">
            <span className="bento-icon">03</span>
            <span className="bento-chip">Standards</span>
          </div>
          <p className="eyebrow">Quality</p>
          <h3>Production-ready execution</h3>
          <p>Performance, accessibility, and maintainability built in from day one.</p>
        </article>
        <article className="card bento-card reveal-on-scroll">
          <div className="bento-head">
            <span className="bento-icon">04</span>
            <span className="bento-chip">Partnership</span>
          </div>
          <p className="eyebrow">Communication</p>
          <h3>Proactive collaboration</h3>
          <p>Clear expectations, fast feedback loops, and thoughtful recommendations at every stage.</p>
        </article>
      </div>
    </section>
  )
}

function ServicesPage() {
  useRevealOnScroll('.services-flow .reveal-on-scroll')

  const services = [
    { title: 'MVP Development', body: 'Fast product iterations with Rails APIs, modern React frontends, and strong foundations.' },
    { title: 'Rescue + Refactor', body: 'Stabilize existing products, pay down risky technical debt, and increase delivery speed.' },
    { title: 'Product Engineering', body: 'Long-term collaboration for roadmap execution, architecture, and feature ownership.' },
  ]

  return (
    <section className="stack-lg services-flow">
      <h1>Services</h1>
      <div className="grid-3">
        {services.map((service) => (
          <article key={service.title} className="card reveal-on-scroll">
            <h3>{service.title}</h3>
            <p>{service.body}</p>
          </article>
        ))}
      </div>
    </section>
  )
}

function PortfolioPage() {
  useRevealOnScroll('.portfolio-flow .reveal-on-scroll')

  return (
    <section className="stack-lg portfolio-flow">
      <h1>Selected Work</h1>
      <div className="grid-2">
        <article className="card reveal-on-scroll">
          <h3>SaaS Dashboard Rebuild</h3>
          <p>Reduced page load by 52%, restructured API boundaries, and shipped analytics features in 6 weeks.</p>
        </article>
        <article className="card reveal-on-scroll">
          <h3>Marketplace Booking Engine</h3>
          <p>Implemented booking pipeline with payment and scheduling integrations, raising conversion by 18%.</p>
        </article>
      </div>
    </section>
  )
}

function ResumePage() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [sections, setSections] = useState<Array<{ id: number; title: string; markdown_body: string }>>([])
  const [siteContent, setSiteContent] = useState<SiteContent>({ hero_photo_url: null, resume_url: null })

  useEffect(() => {
    Promise.allSettled([publicApi.getProfileSections(), publicApi.getSiteContent()])
      .then(([sectionsResult, siteContentResult]) => {
        if (sectionsResult.status === 'fulfilled') {
          setSections(sectionsResult.value)
        } else {
          setError(sectionsResult.reason instanceof Error ? sectionsResult.reason.message : 'Failed to load resume content.')
        }

        if (siteContentResult.status === 'fulfilled') {
          setSiteContent(siteContentResult.value)
        } else {
          setSiteContent({ hero_photo_url: null, resume_url: null })
        }
      })
      .finally(() => setLoading(false))
  }, [])

  if (loading) return <p>Loading resume content...</p>
  if (error) return <p className="error">{error}</p>

  return (
    <section className="stack-lg">
      <h1>Resume</h1>
      {(siteContent.resume_text || siteContent.resume_url) && (
        <article className="card resume-viewer-card stack-sm">
          {siteContent.resume_text ? (
            <div className="resume-text-content">
              <MarkdownContent source={siteContent.resume_text} />
            </div>
          ) : (
            <p className="status">Resume text could not be extracted automatically. Use the PDF link below.</p>
          )}
          {siteContent.resume_url && (
            <div className="button-row">
              <a href={siteContent.resume_url} className="btn btn-ghost" target="_blank" rel="noreferrer">
                Open Resume PDF
              </a>
            </div>
          )}
        </article>
      )}
      {sections.length === 0 ? (
        <p>No resume sections yet. Add content in the admin dashboard.</p>
      ) : (
        sections.map((section) => (
          <article key={section.id} className="card">
            <h2>{section.title}</h2>
            <MarkdownContent source={section.markdown_body} />
          </article>
        ))
      )}
    </section>
  )
}

function BlogListPage() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [posts, setPosts] = useState<BlogPost[]>([])
  useRevealOnScroll('.blog-flow .reveal-on-scroll', posts.length)

  useEffect(() => {
    publicApi
      .getBlogPosts()
      .then((data) => setPosts(data))
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  return (
    <section className="stack-lg blog-flow">
      <h1>Blog</h1>
      {loading && <p>Loading posts...</p>}
      {error && <p className="error">{error}</p>}
      {!loading && posts.length === 0 && <p>No published posts yet.</p>}
      <div className="blog-list-grid">
        {posts.map((post) => {
          const publishedLabel = post.published_at
            ? new Date(post.published_at).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })
            : 'Draft'

          return (
            <article key={post.id} className="card reveal-on-scroll blog-card">
              <div className="blog-card-meta">
                <span className="blog-pill">Article</span>
                <time dateTime={post.published_at ?? ''}>{publishedLabel}</time>
              </div>
              <h2 className="blog-card-title">
                <Link to={`/blog/${post.slug}`} className="blog-card-link">
                  {post.title}
                </Link>
              </h2>
              <p className="blog-card-summary">{post.summary || 'No summary yet.'}</p>
              {post.tag_names && post.tag_names.length > 0 && (
                <div className="blog-tag-row">
                  {post.tag_names.slice(0, 3).map((tag) => (
                    <span key={tag} className="blog-tag-chip">
                      {tag}
                    </span>
                  ))}
                </div>
              )}
              <Link to={`/blog/${post.slug}`} className="text-link blog-card-cta">
                Read article
              </Link>
            </article>
          )
        })}
      </div>
    </section>
  )
}

function BlogDetailPage() {
  const { slug = '' } = useParams()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [post, setPost] = useState<BlogPost | null>(null)
  const [previousPost, setPreviousPost] = useState<BlogPost | null>(null)
  const [nextPost, setNextPost] = useState<BlogPost | null>(null)

  useEffect(() => {
    if (!slug) return
    publicApi
      .getBlogPost(slug)
      .then((data) => setPost(data))
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false))
  }, [slug])

  useEffect(() => {
    if (!slug) return

    publicApi
      .getBlogPosts()
      .then((posts) => {
        const currentIndex = posts.findIndex((item) => item.slug === slug)
        setPreviousPost(currentIndex > 0 ? posts[currentIndex - 1] : null)
        setNextPost(currentIndex >= 0 && currentIndex < posts.length - 1 ? posts[currentIndex + 1] : null)
      })
      .catch(() => {
        setPreviousPost(null)
        setNextPost(null)
      })
  }, [slug])

  if (loading) return <p>Loading post...</p>
  if (error) return <p className="error">{error}</p>
  if (!post) return <p>Post not found.</p>

  const publishedLabel = post.published_at
    ? new Date(post.published_at).toLocaleDateString([], { month: 'long', day: 'numeric', year: 'numeric' })
    : 'Draft'
  const readingMinutes = Math.max(1, Math.round((post.markdown_body ?? '').split(/\s+/).filter(Boolean).length / 220))

  return (
    <article className="stack-lg blog-detail-flow">
      <Link to="/blog" className="text-link blog-back-link">
        &larr; Back to blog
      </Link>
      <header className="card blog-detail-header">
        <div className="blog-detail-meta">
          <span className="blog-pill">Article</span>
          <time dateTime={post.published_at ?? ''}>{publishedLabel}</time>
          <span>{readingMinutes} min read</span>
        </div>
        <h1>{post.title}</h1>
        {post.summary && <p className="blog-detail-summary">{post.summary}</p>}
        {post.tag_names && post.tag_names.length > 0 && (
          <div className="blog-tag-row">
            {post.tag_names.map((tag) => (
              <span key={tag} className="blog-tag-chip">
                {tag}
              </span>
            ))}
          </div>
        )}
      </header>
      <section className="card blog-detail-body">
        <MarkdownContent source={post.markdown_body ?? ''} />
      </section>
      {(previousPost || nextPost) && (
        <section className="next-prev-grid">
          {previousPost && (
            <aside className="card next-article-card">
              <p className="eyebrow">Previous Article</p>
              <h3>
                <Link to={`/blog/${previousPost.slug}`} className="blog-card-link">
                  {previousPost.title}
                </Link>
              </h3>
              <p>{previousPost.summary || 'Revisit the previous article.'}</p>
              <Link to={`/blog/${previousPost.slug}`} className="text-link blog-card-cta">
                Read previous article
              </Link>
            </aside>
          )}
          {nextPost && (
            <aside className="card next-article-card">
              <p className="eyebrow">Next Article</p>
              <h3>
                <Link to={`/blog/${nextPost.slug}`} className="blog-card-link">
                  {nextPost.title}
                </Link>
              </h3>
              <p>{nextPost.summary || 'Continue reading the next article.'}</p>
              <Link to={`/blog/${nextPost.slug}`} className="text-link blog-card-cta">
                Continue to next article
              </Link>
            </aside>
          )}
        </section>
      )}
    </article>
  )
}

function GoogleOauthCallbackPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [status, setStatus] = useState('Connecting your Google Calendar...')
  const token = localStorage.getItem('adminToken')
  const code = searchParams.get('code')
  const oauthError = searchParams.get('error')
  const blockerMessage = oauthError
    ? `Google authorization failed: ${oauthError}`
    : !token
      ? 'Admin session is missing. Please sign in and try again.'
      : !code
        ? 'Missing authorization code from Google callback.'
        : null

  useEffect(() => {
    if (blockerMessage) {
      return
    }

    const authCode = code as string
    const adminToken = token as string
    const redirectUri = `${window.location.origin}${GOOGLE_CALLBACK_PATH}`
    adminApi
      .exchangeGoogleCode(adminToken, authCode, redirectUri)
      .then(() => {
        setStatus('Google Calendar connected. Redirecting...')
        window.setTimeout(() => navigate(ADMIN_PATH, { replace: true }), 400)
      })
      .catch((error: Error) => setStatus(error.message))
  }, [blockerMessage, code, navigate, token])

  return (
    <section className="stack-md">
      <h1>Google Calendar Connection</h1>
      <p>{blockerMessage ?? status}</p>
    </section>
  )
}

function ZoomOauthCallbackPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [status, setStatus] = useState('Connecting your Zoom account...')
  const token = localStorage.getItem('adminToken')
  const code = searchParams.get('code')
  const oauthError = searchParams.get('error')
  const blockerMessage = oauthError
    ? `Zoom authorization failed: ${oauthError}`
    : !token
      ? 'Admin session is missing. Please sign in and try again.'
      : !code
        ? 'Missing authorization code from Zoom callback.'
        : null

  useEffect(() => {
    if (blockerMessage) return

    const authCode = code as string
    const adminToken = token as string
    const redirectUri = zoomRedirectUri()
    adminApi
      .exchangeZoomCode(adminToken, authCode, redirectUri)
      .then(() => {
        setStatus('Zoom connected. Redirecting...')
        window.setTimeout(() => navigate(ADMIN_PATH, { replace: true }), 400)
      })
      .catch((error: Error) => setStatus(error.message))
  }, [blockerMessage, code, navigate, token])

  return (
    <section className="stack-md">
      <h1>Zoom Connection</h1>
      <p>{blockerMessage ?? status}</p>
    </section>
  )
}

function pad2(value: number) {
  return value.toString().padStart(2, '0')
}

function toDateKey(value: Date) {
  return `${value.getFullYear()}-${pad2(value.getMonth() + 1)}-${pad2(value.getDate())}`
}

function buildMonthGrid(month: Date) {
  const firstDay = new Date(month.getFullYear(), month.getMonth(), 1)
  const firstWeekday = firstDay.getDay()
  const start = new Date(firstDay)
  start.setDate(firstDay.getDate() - firstWeekday)
  return Array.from({ length: 42 }, (_, index) => {
    const day = new Date(start)
    day.setDate(start.getDate() + index)
    return day
  })
}

function BookingPage() {
  const [timezone, setTimezone] = useState(Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC')
  const [days, setDays] = useState<AvailabilityDay[]>([])
  const [selectedMonth, setSelectedMonth] = useState(() => {
    const now = new Date()
    return new Date(now.getFullYear(), now.getMonth(), 1)
  })
  const [selectedDate, setSelectedDate] = useState<string | null>(null)
  const [status, setStatus] = useState('')
  const [form, setForm] = useState({ name: '', email: '', topic: 'Website Consultation', notes: '' })
  const [selectedSlot, setSelectedSlot] = useState<{ start_at: string; end_at: string } | null>(null)

  useEffect(() => {
    publicApi
      .getAvailability(timezone)
      .then((res) => {
        setDays(res.days)
        setStatus('')
      })
      .catch((e: Error) => setStatus(e.message))
  }, [timezone])

  const slotsByDate = useMemo(() => {
    return new Map(days.map((day) => [day.date, day.slots]))
  }, [days])

  useEffect(() => {
    if (selectedDate && slotsByDate.has(selectedDate)) return
    const firstAvailableDate = days[0]?.date ?? null
    setSelectedDate(firstAvailableDate)
  }, [days, selectedDate, slotsByDate])

  useEffect(() => {
    setSelectedSlot(null)
  }, [selectedDate])

  const selectedSlots = useMemo(() => {
    if (!selectedDate) return []
    return slotsByDate.get(selectedDate) ?? []
  }, [selectedDate, slotsByDate])

  const monthCells = useMemo(() => buildMonthGrid(selectedMonth), [selectedMonth])

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (!selectedSlot) {
      setStatus('Please choose an available slot.')
      return
    }
    try {
      await publicApi.createMeeting({
        ...form,
        timezone,
        start_at: selectedSlot.start_at,
        end_at: selectedSlot.end_at,
      })
      setStatus('Meeting request submitted. You will receive confirmation once provisioned.')
    } catch (error) {
      setStatus((error as Error).message)
    }
  }

  return (
    <section className="stack-lg">
      <h1>Book a Call</h1>
      <p>Choose a day and available time from my Google Calendar, then share your meeting details.</p>
      <p>All consultations are conducted via Zoom, and your confirmation email will include the meeting link.</p>
      <div className="card stack-md">
        <label>
          Timezone
          <input value={timezone} onChange={(e) => setTimezone(e.target.value)} />
        </label>
        <div className="calendar-controls">
          <button
            type="button"
            className="btn btn-ghost"
            onClick={() => setSelectedMonth(new Date(selectedMonth.getFullYear(), selectedMonth.getMonth() - 1, 1))}
          >
            Previous
          </button>
          <strong>
            {selectedMonth.toLocaleString([], { month: 'long', year: 'numeric' })}
          </strong>
          <button
            type="button"
            className="btn btn-ghost"
            onClick={() => setSelectedMonth(new Date(selectedMonth.getFullYear(), selectedMonth.getMonth() + 1, 1))}
          >
            Next
          </button>
        </div>
        <div className="calendar-grid">
          {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
            <div key={day} className="calendar-weekday">
              {day}
            </div>
          ))}
          {monthCells.map((day) => {
            const key = toDateKey(day)
            const isCurrentMonth = day.getMonth() === selectedMonth.getMonth()
            const availableCount = slotsByDate.get(key)?.length ?? 0
            const isSelected = selectedDate === key
            return (
              <button
                type="button"
                key={key}
                className={`calendar-day ${isSelected ? 'calendar-day-selected' : ''}`}
                disabled={!isCurrentMonth || availableCount === 0}
                onClick={() => setSelectedDate(key)}
              >
                <span>{day.getDate()}</span>
                {availableCount > 0 && <small>{availableCount} slots</small>}
              </button>
            )
          })}
        </div>
        <div className="slot-grid">
          {selectedSlots.map((slot) => {
            const label = new Date(slot.start_at).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })
            const active = selectedSlot?.start_at === slot.start_at
            return (
              <button
                type="button"
                key={slot.start_at}
                className={`slot-button ${active ? 'slot-button-active' : ''}`}
                onClick={() => setSelectedSlot(slot)}
              >
                {label}
              </button>
            )
          })}
          {selectedSlots.length === 0 && <p>Select a date with available slots.</p>}
        </div>
      </div>

      <form className="card stack-md" onSubmit={submit}>
        <label>
          Name
          <input required value={form.name} onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))} />
        </label>
        <label>
          Email
          <input
            required
            type="email"
            value={form.email}
            onChange={(e) => setForm((prev) => ({ ...prev, email: e.target.value }))}
          />
        </label>
        <label>
          Topic
          <input value={form.topic} onChange={(e) => setForm((prev) => ({ ...prev, topic: e.target.value }))} />
        </label>
        <label>
          Notes
          <textarea value={form.notes} onChange={(e) => setForm((prev) => ({ ...prev, notes: e.target.value }))} />
        </label>
        <button type="submit" className="btn btn-primary">
          Request Meeting
        </button>
      </form>
      {status && <p className="status">{status}</p>}
    </section>
  )
}

function AdminPage() {
  const [token, setToken] = useState<string>(() => localStorage.getItem('adminToken') ?? '')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [posts, setPosts] = useState<BlogPost[]>([])
  const [selected, setSelected] = useState<BlogPost | null>(null)
  const [status, setStatus] = useState('')
  const [integrations, setIntegrations] = useState<
    Array<{ provider: string; active: boolean; external_account_id: string | null; expires_at: string | null; expired: boolean }>
  >([])
  const [heroPhotoUrl, setHeroPhotoUrl] = useState<string | null>(null)
  const [heroPhotoFile, setHeroPhotoFile] = useState<File | null>(null)
  const [resumeUrl, setResumeUrl] = useState<string | null>(null)
  const [resumeFile, setResumeFile] = useState<File | null>(null)
  const [resumeDropActive, setResumeDropActive] = useState(false)
  const [activeTab, setActiveTab] = useState<'profile' | 'integrations' | 'blog'>('profile')
  const navigate = useNavigate()

  const load = async (currentToken: string) => {
    const [postData, integrationPayload] = await Promise.all([
      adminApi.getPosts(currentToken),
      adminApi.getIntegrations(currentToken),
    ])
    const siteContent = await adminApi.getSiteContent(currentToken)
    setPosts(postData)
    setSelected(postData[0] ?? null)
    setHeroPhotoUrl(siteContent.hero_photo_url)
    setResumeUrl(siteContent.resume_url)
    setIntegrations(integrationPayload.integrations)
  }

  useEffect(() => {
    if (!token) return
    // eslint-disable-next-line react-hooks/set-state-in-effect
    load(token).catch((e: Error) => setStatus(e.message))
  }, [token])

  const login = async (e: FormEvent) => {
    e.preventDefault()
    try {
      const response = await adminApi.login(email, password)
      localStorage.setItem('adminToken', response.token)
      setToken(response.token)
      setStatus('Logged in.')
      navigate(ADMIN_PATH)
    } catch (error) {
      setStatus((error as Error).message)
    }
  }

  const save = async () => {
    if (!token || !selected) return
    try {
      const payload = {
        ...selected,
        tag_names: selected.tag_names ?? [],
      }
      const saved = await adminApi.savePost(token, payload)
      setStatus('Post saved.')
      await load(token)
      setSelected(saved)
    } catch (error) {
      setStatus((error as Error).message)
    }
  }

  const createPost = () => {
    setSelected({
      id: 0,
      title: 'New Post',
      slug: '',
      summary: '',
      markdown_body: '# New Post',
      status: 'draft',
      published_at: null,
      scheduled_for: null,
      tag_names: [],
    })
  }

  const remove = async () => {
    if (!token || !selected?.id) return
    try {
      await adminApi.deletePost(token, selected.id)
      await load(token)
      setStatus('Post deleted.')
    } catch (error) {
      setStatus((error as Error).message)
    }
  }

  const uploadHeroPhoto = async () => {
    if (!token || !heroPhotoFile) return
    try {
      const content = await adminApi.uploadHeroPhoto(token, heroPhotoFile)
      setHeroPhotoUrl(content.hero_photo_url)
      setHeroPhotoFile(null)
      setStatus('Landing photo uploaded.')
    } catch (error) {
      setStatus((error as Error).message)
    }
  }

  const deleteHeroPhoto = async () => {
    if (!token) return
    try {
      await adminApi.removeHeroPhoto(token)
      setHeroPhotoUrl(null)
      setStatus('Landing photo removed.')
    } catch (error) {
      setStatus((error as Error).message)
    }
  }

  const uploadResume = async (fileOverride?: File) => {
    const file = fileOverride ?? resumeFile
    if (!token || !file) return
    try {
      const content = await adminApi.uploadResume(token, file)
      setResumeUrl(content.resume_url)
      setResumeFile(null)
      setStatus('Resume uploaded.')
    } catch (error) {
      setStatus((error as Error).message)
    }
  }

  const selectResumeFile = (file: File | null) => {
    if (!file) return
    const isPdf = file.type === 'application/pdf' || file.name.toLowerCase().endsWith('.pdf')
    if (!isPdf) {
      setStatus('Please upload a PDF file for the resume.')
      return
    }

    setResumeFile(file)
    setStatus(`Uploading ${file.name}...`)
    void uploadResume(file)
  }

  const handleResumeDragOver = (event: DragEvent<HTMLDivElement>) => {
    event.preventDefault()
    setResumeDropActive(true)
  }

  const handleResumeDragLeave = (event: DragEvent<HTMLDivElement>) => {
    event.preventDefault()
    setResumeDropActive(false)
  }

  const handleResumeDrop = (event: DragEvent<HTMLDivElement>) => {
    event.preventDefault()
    setResumeDropActive(false)
    const file = event.dataTransfer.files?.[0] ?? null
    selectResumeFile(file)
  }

  const deleteResume = async () => {
    if (!token) return
    try {
      await adminApi.removeResume(token)
      setResumeUrl(null)
      setResumeFile(null)
      setStatus('Resume removed.')
    } catch (error) {
      setStatus((error as Error).message)
    }
  }

  const connectGoogle = () => {
    if (!GOOGLE_CLIENT_ID) {
      setStatus('Missing VITE_GOOGLE_CLIENT_ID in client/.env')
      return
    }
    const redirectUri = `${window.location.origin}${GOOGLE_CALLBACK_PATH}`
    const oauthUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth')
    oauthUrl.searchParams.set('client_id', GOOGLE_CLIENT_ID)
    oauthUrl.searchParams.set('redirect_uri', redirectUri)
    oauthUrl.searchParams.set('response_type', 'code')
    oauthUrl.searchParams.set('scope', GOOGLE_OAUTH_SCOPE)
    oauthUrl.searchParams.set('access_type', 'offline')
    oauthUrl.searchParams.set('prompt', 'consent')
    window.location.href = oauthUrl.toString()
  }

  const connectZoom = () => {
    if (!ZOOM_CLIENT_ID) {
      setStatus('Missing VITE_ZOOM_CLIENT_ID in client/.env')
      return
    }
    const redirectUri = zoomRedirectUri()
    const oauthUrl = new URL('https://zoom.us/oauth/authorize')
    oauthUrl.searchParams.set('client_id', ZOOM_CLIENT_ID)
    oauthUrl.searchParams.set('redirect_uri', redirectUri)
    oauthUrl.searchParams.set('response_type', 'code')
    window.location.href = oauthUrl.toString()
  }

  if (!token) {
    return (
      <section className="stack-md">
        <h1>Admin Login</h1>
        <form className="card stack-md" onSubmit={login}>
          <label>
            Email
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
          </label>
          <label>
            Password
            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
          </label>
          <button className="btn btn-primary" type="submit">
            Sign In
          </button>
        </form>
        {status && <p className="status">{status}</p>}
      </section>
    )
  }

  return (
    <section className="stack-lg admin-shell">
      <h1>Admin Dashboard</h1>
      <div className="admin-layout">
        <aside className="card admin-sidebar">
          <button
            className={`admin-tab-btn ${activeTab === 'profile' ? 'admin-tab-btn-active' : ''}`}
            onClick={() => setActiveTab('profile')}
          >
            Profile
          </button>
          <button
            className={`admin-tab-btn ${activeTab === 'integrations' ? 'admin-tab-btn-active' : ''}`}
            onClick={() => setActiveTab('integrations')}
          >
            Integrations
          </button>
          <button
            className={`admin-tab-btn ${activeTab === 'blog' ? 'admin-tab-btn-active' : ''}`}
            onClick={() => setActiveTab('blog')}
          >
            Blog
          </button>
        </aside>

        <div className="admin-panel stack-lg">
          {activeTab === 'profile' && (
            <>
              <article className="card stack-md">
                <h2>Landing Photo</h2>
                <div className="hero-photo-admin">
                  {heroPhotoUrl ? (
                    <img src={heroPhotoUrl} alt="Current landing profile" className="hero-photo" />
                  ) : (
                    <div className="hero-photo hero-photo-placeholder">No photo uploaded yet</div>
                  )}
                  <div className="stack-sm">
                    <label>
                      Upload image
                      <input
                        type="file"
                        accept="image/png,image/jpeg,image/webp"
                        onChange={(e) => setHeroPhotoFile(e.target.files?.[0] ?? null)}
                      />
                    </label>
                    <div className="button-row">
                      <button className="btn btn-primary" onClick={uploadHeroPhoto} disabled={!heroPhotoFile}>
                        Upload Photo
                      </button>
                      <button className="btn btn-ghost" onClick={deleteHeroPhoto} disabled={!heroPhotoUrl}>
                        Remove Photo
                      </button>
                    </div>
                  </div>
                </div>
              </article>

              <article className="card stack-md">
                <h2>Resume (PDF)</h2>
                <p className="status">Upload a PDF resume that appears inline on the public Resume page.</p>
                {resumeUrl ? (
                  <a href={resumeUrl} target="_blank" rel="noreferrer" className="text-link">
                    Preview current resume
                  </a>
                ) : (
                  <p className="status">No resume uploaded yet.</p>
                )}
                <div
                  className={`resume-dropzone ${resumeDropActive ? 'resume-dropzone-active' : ''}`}
                  onDragOver={handleResumeDragOver}
                  onDragEnter={handleResumeDragOver}
                  onDragLeave={handleResumeDragLeave}
                  onDrop={handleResumeDrop}
                >
                  <p>Drag and drop your PDF resume here</p>
                  <p className="status">or</p>
                  <label className="btn btn-ghost resume-browse-btn">
                    Choose PDF
                    <input
                      type="file"
                      accept="application/pdf,.pdf"
                      className="resume-file-input-hidden"
                      onChange={(e) => selectResumeFile(e.target.files?.[0] ?? null)}
                    />
                  </label>
                  {resumeFile && <p className="status">Ready to upload: {resumeFile.name}</p>}
                </div>
                <div className="button-row">
                  <button className="btn btn-primary" onClick={() => uploadResume()} disabled={!resumeFile}>
                    Upload Resume
                  </button>
                  <button className="btn btn-ghost" onClick={deleteResume} disabled={!resumeUrl}>
                    Remove Resume
                  </button>
                </div>
              </article>
            </>
          )}

          {activeTab === 'integrations' && (
            <article className="card stack-md">
              <h2>Calendar Availability</h2>
              <p className="status">Availability is managed directly in Google Calendar. Mark a time as busy there to block booking.</p>
              <div className="button-row">
                <button className="btn btn-primary" onClick={connectGoogle}>
                  Connect Google Calendar
                </button>
                <button className="btn btn-primary" onClick={connectZoom}>
                  Connect Zoom
                </button>
                <button className="btn btn-ghost" onClick={() => load(token)}>
                  Refresh Integration Status
                </button>
              </div>
              <p className="status">
                {integrations.length > 0
                  ? integrations
                      .map((item) => `${item.provider}: ${item.active ? 'connected' : 'disconnected'}${item.expired ? ' (expired)' : ''}`)
                      .join(' | ')
                  : 'No integrations connected yet.'}
              </p>
            </article>
          )}

          {activeTab === 'blog' && (
            <div className="grid-2">
              <aside className="card stack-sm">
                <div className="button-row">
                  <button className="btn btn-ghost" onClick={createPost}>
                    New Post
                  </button>
                </div>
                {posts.map((post) => (
                  <button key={post.id} className="list-button" onClick={() => setSelected(post)}>
                    {post.title} <small>{post.status}</small>
                  </button>
                ))}
              </aside>
              <article className="card stack-md">
                {!selected ? (
                  <p>Select a post.</p>
                ) : (
                  <>
                    <label>
                      Title
                      <input value={selected.title} onChange={(e) => setSelected({ ...selected, title: e.target.value })} />
                    </label>
                    <label>
                      Slug
                      <input value={selected.slug ?? ''} onChange={(e) => setSelected({ ...selected, slug: e.target.value })} />
                    </label>
                    <label>
                      Summary
                      <textarea
                        value={selected.summary ?? ''}
                        onChange={(e) => setSelected({ ...selected, summary: e.target.value })}
                      />
                    </label>
                    <label>
                      Status
                      <select value={selected.status} onChange={(e) => setSelected({ ...selected, status: e.target.value })}>
                        <option value="draft">draft</option>
                        <option value="scheduled">scheduled</option>
                        <option value="published">published</option>
                        <option value="archived">archived</option>
                      </select>
                    </label>
                    <label>
                      Tags (comma separated)
                      <input
                        value={(selected.tag_names ?? []).join(', ')}
                        onChange={(e) =>
                          setSelected({
                            ...selected,
                            tag_names: e.target.value
                              .split(',')
                              .map((item) => item.trim())
                              .filter(Boolean),
                          })
                        }
                      />
                    </label>
                    <label>
                      Markdown Content
                      <textarea
                        className="markdown-editor"
                        value={selected.markdown_body ?? ''}
                        onChange={(e) => setSelected({ ...selected, markdown_body: e.target.value })}
                      />
                    </label>
                    <div className="button-row">
                      <button className="btn btn-primary" onClick={save}>
                        Save
                      </button>
                      <button className="btn btn-danger" onClick={remove} disabled={!selected.id}>
                        Delete
                      </button>
                    </div>
                  </>
                )}
              </article>
            </div>
          )}
        </div>
      </div>
      {status && <p className="status">{status}</p>}
    </section>
  )
}

export default App
