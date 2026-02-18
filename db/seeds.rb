ProfileSection.find_or_create_by!(key: "about") do |section|
  section.title = "About"
  section.position = 1
  section.markdown_body = <<~MD
    ## Senior Freelance Developer

    I design and build scalable web apps with **Rails APIs** and modern **React frontends**.
    My focus is business outcomes, maintainable code, and shipping quickly.
  MD
end

ProfileSection.find_or_create_by!(key: "experience") do |section|
  section.title = "Experience Highlights"
  section.position = 2
  section.markdown_body = <<~MD
    - Built SaaS products used by thousands of users.
    - Led architecture for booking and calendar-integrated workflows.
    - Improved delivery speed by refactoring legacy codebases.
  MD
end

post = BlogPost.find_or_initialize_by(slug: "welcome-to-my-portfolio-blog")
post.title = "Welcome to my portfolio blog"
post.summary = "Why I built this site and how I approach product-focused engineering."
post.markdown_body = <<~MD
  # Welcome

  This blog documents practical build notes, architecture decisions, and product delivery lessons.

  ## What you can expect

  - Technical deep dives
  - Delivery tradeoffs and decisions
  - Build-in-public updates
MD
post.status = "published"
post.published_at ||= Time.current
post.save!

post = BlogPost.find_or_initialize_by(slug: "building-reliable-client-workflows")
post.title = "Building Reliable Client Workflows"
post.summary = "How I structure freelance delivery from kickoff to launch without losing momentum."
post.markdown_body = <<~MD
  # Building Reliable Client Workflows

  Strong delivery is mostly about clarity and cadence.

  ## What I optimize for

  - Fast decision loops
  - Visible progress each week
  - Fewer late surprises

  ## Practical system

  I break work into weekly milestones, define success criteria up front, and keep scope intentional.
MD
post.status = "published"
post.published_at ||= Time.current
post.save!

post = BlogPost.find_or_initialize_by(slug: "website-performance-wins-that-convert")
post.title = "Website Performance Wins That Convert"
post.summary = "Small performance improvements that measurably improve trust and conversion on service websites."
post.markdown_body = <<~MD
  # Website Performance Wins That Convert

  Performance is a product feature, not a polish step.

  ## High-impact improvements

  - Compress and properly size media
  - Reduce render-blocking assets
  - Keep UI interactions responsive

  ## Why this matters

  Faster pages reduce friction and help visitors stay engaged long enough to act.
MD
post.status = "published"
post.published_at ||= Time.current
post.save!

availability = [
  { weekday: 2, start_time: "09:00", end_time: "12:00" },
  { weekday: 4, start_time: "13:00", end_time: "16:00" }
]
availability.each do |rule|
  AvailabilityRule.find_or_create_by!(
    weekday: rule[:weekday],
    timezone: "UTC",
    start_time: rule[:start_time],
    end_time: rule[:end_time]
  )
end
