#!/usr/bin/env ruby
require 'x'
require 'dotenv/load'
require 'json'
require 'time'

class AutoPoster
  CONTENT_TEMPLATES = [
    {
      type: :rails_tip,
      templates: [
        "CONTENT_PLACEHOLDER\n\nJust used this pattern in my latest railsui.com component 🚀",
        "Rails tip: CONTENT_PLACEHOLDER\n\nSaved me hours while building railsui.com templates",
        "CONTENT_PLACEHOLDER\n\nThis is why I love Rails development so much",
        "Found this gem: CONTENT_PLACEHOLDER\n\nWish I knew this sooner for railsui.com",
        "CONTENT_PLACEHOLDER\n\nMy go-to pattern for every railsui.com component now"
      ]
    },
    {
      type: :tailwind_tip,
      templates: [
        "Tailwind discovery: CONTENT_PLACEHOLDER\n\nUsing this in all my railsui.com components now",
        "CONTENT_PLACEHOLDER\n\nGame changer for my railsui.com design system",
        "CSS moment: CONTENT_PLACEHOLDER\n\nWhy didn't I know this earlier?",
        "CONTENT_PLACEHOLDER\n\nThis combo makes railsui.com components so much cleaner ✨",
        "Tailwind tip: CONTENT_PLACEHOLDER\n\nMy new favorite pattern"
      ]
    },
    {
      type: :ui_insight,
      templates: [
        "UI realization: CONTENT_PLACEHOLDER\n\nChanged how I approach every railsui.com design",
        "CONTENT_PLACEHOLDER\n\nThis thinking transformed my railsui.com components",
        "Design truth: CONTENT_PLACEHOLDER\n\nLearned this the hard way",
        "CONTENT_PLACEHOLDER\n\nWhy I rebuilt half of railsui.com with this principle",
        "UX insight: CONTENT_PLACEHOLDER\n\nMy biggest design lesson this year"
      ]
    },
    {
      type: :building_public,
      templates: [
        "Building railsui.com: CONTENT_PLACEHOLDER",
        "CONTENT_PLACEHOLDER\n\nThe reality of shipping products as a solo dev 🛠️",
        "Product lesson: CONTENT_PLACEHOLDER\n\nLearned this building railsui.com",
        "CONTENT_PLACEHOLDER\n\nWhy railsui.com took me longer than expected",
        "Startup truth: CONTENT_PLACEHOLDER\n\nNo one talks about this part"
      ]
    },
    {
      type: :rails_8_feature,
      templates: [
        "Rails 8: CONTENT_PLACEHOLDER\n\nAlready loving this in my railsui.com setup",
        "CONTENT_PLACEHOLDER\n\nRails 8 is changing how I build everything",
        "Rails 8 gem: CONTENT_PLACEHOLDER\n\nThis is exactly what I needed",
        "CONTENT_PLACEHOLDER\n\nWhy I'm excited about Rails 8 for railsui.com",
        "Rails 8 feature: CONTENT_PLACEHOLDER\n\nSimplifying my stack"
      ]
    }
  ]

  CONTENT_BANK = {
    rails_tip: [
      "Rails 8's authentication generator creates a complete auth system in seconds. No more Devise setup headaches",
      "Use `&.` safe navigation everywhere. `@user&.name` is cleaner than checking nil first",
      "Turbo 8 morphing makes page updates feel instant. Set `data-turbo-action='morph'` on your links",
      "Rails 8 defaults to Propshaft. Way faster than Sprockets and handles modern JS better",
      "Use `rails db:seed:replant` to refresh seeds without dropping tables. Saves me daily",
      "Stimulus controllers auto-register from `app/javascript/controllers/`. No more manual imports",
      "Rails 8's `allow_browser` helper blocks old browsers automatically. Set it and forget it",
      "Use `delegate` to clean up models. `delegate :name, to: :user` beats writing methods",
      "Turbo Streams can update multiple elements from one action. Changed my whole approach",
      "Rails 8's rate limiting is built-in now. `rate_limit to: 10, within: 1.minute` done",
      "Use `content_for` to inject CSS/JS only when partials render. Keeps pages clean",
      "Rails 8's queue adapter defaults to Solid Queue. Background jobs without Redis",
      "ActiveRecord `includes` prevents N+1 queries. Always preload what you'll use",
      "Use `form_with local: false` for AJAX forms. Turbo handles the rest beautifully",
      "Rails 8's cable adapter uses Solid Cable. Real-time features without external deps",
      "Use `rails credentials:edit` for all secrets. Never commit API keys again",
      "Rails 8's cache store defaults to Solid Cache. File-based caching that actually works",
      "Stimulus `data-action` accepts multiple events: `click->ctrl#save keyup->ctrl#validate`",
      "Use `before_action :authenticate_user!` with Rails 8 auth. Simple and secure",
      "Rails 8's deployment story with Kamal is incredible. Docker to production in minutes"
    ],

    tailwind_tip: [
      "Use `space-y-4` instead of individual margins. Consistent spacing with zero effort",
      "Combine `flex items-center justify-between` for perfect header layouts every time",
      "Use `prose max-w-none` for blog content. Beautiful typography instantly",
      "Group hover states: `group-hover:text-blue-500` lets parents control children",
      "Use `aspect-square` for consistent image ratios. No more padding-bottom hacks",
      "Grid magic: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3` for responsive layouts",
      "Use `ring-2 ring-blue-500` for focus states. Looks way better than borders",
      "Arbitrary values work: `top-[13px]` when you need pixel-perfect positioning",
      "Use `text-balance` for headlines. Prevents awkward line breaks",
      "Combine `backdrop-blur-sm bg-white/80` for modern glass effects",
      "Use `has-[:checked]:bg-blue-500` for parent styling based on child state",
      "Negative margins: `-mt-8` to pull elements into previous sections",
      "Use `peer` classes for sibling styling. Input focus affects adjacent labels",
      "Combine `shadow-sm shadow-black/5` for subtle, modern shadows",
      "Use `size-6` instead of `w-6 h-6`. Cleaner for square elements",
      "Container queries: `@container (min-width: 20rem)` for component-based responsive design",
      "Use `scroll-smooth` on html for butter-smooth anchor scrolling",
      "Combine `border-0 ring-1 ring-gray-300` for modern input styling",
      "Use `text-pretty` for better paragraph line breaks than `text-balance`",
      "Gradient text: `bg-gradient-to-r from-blue-500 to-purple-600 bg-clip-text text-transparent`"
    ],

    ui_insight: [
      "White space isn't empty space. It's a design element that guides attention",
      "Users scan in F-patterns. Put important stuff top-left and down the left edge",
      "Consistent spacing creates visual rhythm. Stick to multiples of 4 or 8",
      "Color has psychology. Red doesn't always mean danger, green doesn't always mean success",
      "Loading states prevent perceived slowness. Show something immediately",
      "Form errors should appear inline, not in separate alert boxes",
      "Dark mode needs its own design system. It's not just inverted colors",
      "Every icon should have a purpose. Decorative icons just add noise",
      "Typography hierarchy should be obvious. H1 > H2 > H3 needs visual weight",
      "Hover states provide essential feedback. Every clickable thing needs them",
      "Mobile-first forces you to prioritize. Desktop becomes the enhancement",
      "Empty states are UX opportunities. Tell users what to do next",
      "Micro-interactions add personality. Subtle animations make interfaces alive",
      "Consistent button styles build trust. Users learn your patterns",
      "Accessibility benefits everyone. Good contrast and keyboard nav aren't optional",
      "Progressive disclosure reduces cognitive load. Don't show everything at once",
      "Familiar patterns reduce learning curves. Don't reinvent common interactions",
      "Visual feedback confirms actions. Users need to know their click registered",
      "Information architecture beats pretty design. Users need to find stuff first",
      "Performance is a feature. Fast beats beautiful every time"
    ],

    building_public: [
      "Spent 4 hours perfecting a button component. Sounds crazy but details compound",
      "User feedback beats my assumptions every single time. Always test ideas first",
      "Shipping incomplete features taught me more than planning perfect ones",
      "Documentation is a feature. If users can't figure it out, it doesn't exist",
      "Performance matters more than features. Fast and simple wins every time",
      "Consistency is harder than innovation. Matching patterns takes real discipline",
      "Real users find edge cases I never imagined. Every. Single. Time",
      "Refactoring is product work. Clean code means faster feature development",
      "Testing with 5 users reveals 90% of usability issues. Don't skip this",
      "Small improvements compound into big wins. Iterations beat revolutions",
      "My favorite feature is usually not the users' favorite. Ego check needed",
      "Shipping broken beats perfect unshipped. You can't improve what's not live",
      "Automated tests save sanity. Manual testing burns out the whole team",
      "Mobile-first isn't optional anymore. Most traffic comes from phones",
      "Simple onboarding beats complex features. First impressions are everything",
      "Building in public keeps me accountable. Harder to quit when people watch",
      "Solo development is lonely. Twitter became my rubber duck debugging partner",
      "Perfectionism is the enemy of progress. Good enough shipped beats perfect planned",
      "Revenue validates ideas better than compliments. Money talks loudest",
      "Burnout is real. Taking breaks actually speeds up development long-term"
    ],

    rails_8_feature: [
      "Solid Queue eliminates Redis for background jobs. One less service to manage",
      "Solid Cable makes WebSockets work without external dependencies. Real-time features simplified",
      "Solid Cache uses SQLite for caching. Fast, reliable, and no Redis needed",
      "Kamal deployment is a game changer. Docker to production in one command",
      "Propshaft asset pipeline is blazing fast. Goodbye Sprockets compilation wait",
      "Built-in authentication generator creates secure auth in seconds. No more Devise complexity",
      "Rails 8 defaults are production-ready. Less configuration, more building",
      "Allow browser helper blocks old browsers automatically. Progressive enhancement built-in",
      "Rate limiting is now built-in. Protect your app without external gems",
      "Turbo 8 morphing makes updates feel instant. Page changes without full reloads",
      "Rails 8's job queues are database-backed. Simpler deployment, fewer moving parts",
      "Stimulus improvements make JavaScript feel native. Rails and JS playing nicely",
      "Rails 8's caching story is complete. Fast apps without Redis complexity",
      "Action Cable improvements make real-time features actually reliable",
      "Rails 8's deployment pipeline is chef's kiss. From code to production seamlessly",
      "Thruster HTTP/2 proxy comes built-in. Fast static assets without nginx config",
      "Rails 8's authentication is secure by default. No more rolling your own crypto",
      "Solid adapters work everywhere. SQLite scales further than people think",
      "Rails 8's job processing is rock solid. Background work without the headaches",
      "Kamal + Rails 8 = deployment nirvana. Docker deployment without the Docker complexity"
    ]
  }

  TIMING_FILE = 'posting_schedule.json'
  LOG_FILE = 'posted_content.log'

  def initialize
    x_credentials = {
      api_key: ENV['X_API_KEY'],
      api_key_secret: ENV['X_API_KEY_SECRET'],
      access_token: ENV['X_ACCESS_TOKEN'],
      access_token_secret: ENV['X_ACCESS_TOKEN_SECRET']
    }

    @client = X::Client.new(**x_credentials)
    @timing_data = load_timing_data
  end

  def load_timing_data
    if File.exist?(TIMING_FILE)
      JSON.parse(File.read(TIMING_FILE))
    else
      {}
    end
  end

  def save_timing_data
    File.write(TIMING_FILE, JSON.pretty_generate(@timing_data))
  end

  def generate_post
    content_type = CONTENT_BANK.keys.sample
    template_group = CONTENT_TEMPLATES.find { |t| t[:type] == content_type }
    template = template_group[:templates].sample
    content = CONTENT_BANK[content_type].sample

    formatted_post = template.gsub('CONTENT_PLACEHOLDER', content)

    # Ensure tweet is under 280 characters
    if formatted_post.length > 280
      excess = formatted_post.length - 277
      content = content[0..-(excess + 4)] + "..."
      formatted_post = template.gsub('CONTENT_PLACEHOLDER', content)
    end

    formatted_post
  end

  def should_post_today?
    return false unless @timing_data['last_posted_at']

    last_posted = Time.parse(@timing_data['last_posted_at'])
    days_since_last_post = (Time.now - last_posted) / (24 * 60 * 60)

    # Post 1-2 times per week (3-7 days apart)
    min_days = 3
    max_days = 7

    return false if days_since_last_post < min_days

    # Increase probability as days pass
    if days_since_last_post >= max_days
      true
    else
      # Random chance increases over time
      probability = (days_since_last_post - min_days) / (max_days - min_days)
      rand < probability
    end
  end

  def time_to_post?
    # First time posting
    return true unless @timing_data['last_posted_at']

    should_post_today?
  end

  def post_to_x
    unless time_to_post?
      puts "⏰ Not time to post yet. Check back later."
      return
    end

    begin
      content = generate_post
      @client.post("tweets", { text: content }.to_json)
      puts "✅ Posted: #{content}"

      # Update timing data
      @timing_data['last_posted_at'] = Time.now.iso8601
      save_timing_data

      # Log to file
      File.open(LOG_FILE, 'a') do |f|
        f.puts "#{Time.now}: #{content}\n"
      end

    rescue X::Error => e
      puts "❌ X API error: #{e.message}"
    rescue => e
      puts "❌ Error posting to X: #{e.message}"
    end
  end

  def demo_run
    puts "🎬 Demo run - showing what would be posted:"
    puts "=" * 50

    content = generate_post
    puts content
    puts "=" * 50
    puts "Character count: #{content.length}/280"
    puts "Time to post: #{time_to_post? ? 'YES' : 'NO'}"

    if @timing_data['last_posted_at']
      last_posted = Time.parse(@timing_data['last_posted_at'])
      days_since = (Time.now - last_posted) / (24 * 60 * 60)
      puts "Days since last post: #{days_since.round(1)}"
    else
      puts "No previous posts recorded"
    end
  end

  def status
    puts "📊 Posting Status:"
    puts "=" * 30

    if @timing_data['last_posted_at']
      last_posted = Time.parse(@timing_data['last_posted_at'])
      days_since = (Time.now - last_posted) / (24 * 60 * 60)
      puts "Last posted: #{last_posted.strftime('%Y-%m-%d %H:%M:%S')}"
      puts "Days since last post: #{days_since.round(1)}"
      puts "Ready to post: #{time_to_post? ? 'YES' : 'NO'}"
    else
      puts "No previous posts recorded"
      puts "Ready to post: YES (first time)"
    end

    puts "Content types: #{CONTENT_BANK.keys.join(', ')}"
    puts "Total content items: #{CONTENT_BANK.values.flatten.length}"
  end
end

# Command line interface
if __FILE__ == $0
  poster = AutoPoster.new

  case ARGV[0]
  when 'demo'
    poster.demo_run
  when 'status'
    poster.status
  when 'post'
    poster.post_to_x
  else
    puts "Usage:"
    puts "  ruby auto_poster.rb demo    # Show what would be posted"
    puts "  ruby auto_poster.rb status  # Show posting status"
    puts "  ruby auto_poster.rb post    # Post if it's time"
    puts ""
    puts "Running demo by default..."
    poster.demo_run
  end
end
