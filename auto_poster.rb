#!/usr/bin/env ruby
require 'x'
require 'dotenv/load'
require 'json'
require 'time'
require 'openai'

class AutoPoster
  # Fallback content templates (used if AI fails)
  FALLBACK_TEMPLATES = [
    {
      type: :rails_tip,
      templates: [
        "CONTENT_PLACEHOLDER\n\nJust used this pattern in my latest Rails UI component 🚀",
        "Rails tip: CONTENT_PLACEHOLDER\n\nSaved me hours while building Rails UI templates and components",
        "CONTENT_PLACEHOLDER\n\nThis is why I love Rails development so much"
      ]
    },
    {
      type: :tailwind_tip,
      templates: [
        "Tailwind discovery: CONTENT_PLACEHOLDER\n\nUsing this in all my Rails UI components now",
        "CONTENT_PLACEHOLDER\n\nGame changer for my Rails UI design system"
      ]
    },
    {
      type: :ui_insight,
      templates: [
        "CONTENT_PLACEHOLDER\n\nChanged how I approach every Rails UI design",
        "CONTENT_PLACEHOLDER\n\nThis thinking transformed my railsui.com components"
      ]
    },
    {
      type: :building_public,
      templates: [
        "CONTENT_PLACEHOLDER",
        "CONTENT_PLACEHOLDER\n\nThe reality of shipping as a solo dev 🛠️",
        "Product lesson: CONTENT_PLACEHOLDER\n\nLearned this the hard way"
      ]
    },
    {
      type: :rails_8_feature,
      templates: [
        "Rails 8: CONTENT_PLACEHOLDER\n\nAlready loving this in my railsui.com setup",
        "CONTENT_PLACEHOLDER\n\nRails 8 is changing how I build everything",
        "Rails 8 feature: CONTENT_PLACEHOLDER\n\nExactly what I needed"
      ]
    }
  ]

  FALLBACK_CONTENT = {
    rails_tip: [
      "Rails 8's authentication generator creates a complete auth system in seconds",
      "Use `&.` safe navigation everywhere. `@user&.name` is cleaner than checking nil first",
      "Turbo 8 morphing makes page updates feel instant. Set `data-turbo-action='morph'` on your links"
    ],
    tailwind_tip: [
      "Use `space-y-4` instead of individual margins. Consistent spacing with zero effort",
      "Combine `flex items-center justify-between` for perfect header layouts every time",
      "Use `prose max-w-none` for blog content. Beautiful typography instantly"
    ],
    ui_insight: [
      "White space isn't empty space. It's a design element that guides attention",
      "Users scan in F-patterns. Put important stuff top-left and down the left edge",
      "Loading states prevent perceived slowness. Show something immediately"
    ],
    building_public: [
      "Spent 4 hours perfecting a button component. Details compound",
      "User feedback beats my assumptions every time. Always test ideas first",
      "Shipping broken beats perfect unshipped. You can't improve what's not live",
      "Building in public keeps me accountable. Harder to quit when people watch"
    ],
    rails_8_feature: [
      "Solid Queue eliminates Redis for background jobs. One less service to manage",
      "Rails 8's authentication generator creates secure auth in seconds",
      "Kamal deployment is a game changer. Docker to production in one command",
      "Rails 8's built-in rate limiting protects apps without external gems"
    ]
  }

  # AI prompts for different content types
  AI_PROMPTS = {
    rails_tip: "You are a Rails developer building railsui.com. Write a short, practical Rails tip in first person. Focus on Rails 8 features, development patterns, or time-saving techniques. Keep it under 200 chars. Sound like a real developer sharing something they just discovered. Examples: 'Rails 8's Solid Queue eliminates Redis for background jobs', 'Use `&.` safe navigation everywhere', 'Turbo 8 morphing makes updates feel instant'",

    tailwind_tip: "You are a developer building railsui.com components. Write a short, practical Tailwind CSS tip in first person. Focus on utility classes, responsive design, or modern CSS patterns. Keep it under 200 chars. Sound like a real developer sharing a discovery. Examples: 'Use `space-y-4` instead of individual margins', 'Combine `flex items-center justify-between` for perfect layouts', 'Use `prose max-w-none` for blog content'",

    ui_insight: "You are a developer building railsui.com. Write a short UI/UX insight in first person. Focus on design principles, user behavior, or interface patterns. Keep it under 200 chars. Sound like a real developer sharing a realization. Examples: 'White space isn't empty space. It's a design element', 'Users scan in F-patterns', 'Loading states prevent perceived slowness'",

    building_public: "You are a solo developer building railsui.com. Write a short insight about building products in public in first person. Focus on honest experiences, lessons learned, or startup realities. Keep it under 200 chars. Sound authentic and human. Examples: 'Spent 4 hours perfecting a button component. Details compound', 'User feedback beats my assumptions every time', 'Shipping broken beats perfect unshipped'",

    rails_8_feature: "You are a Rails developer excited about Rails 8. Write a short insight about a Rails 8 feature in first person. Focus on Solid Queue, Kamal, Propshaft, built-in auth, or other Rails 8 improvements. Keep it under 200 chars. Sound like a developer who's actually using these features. Examples: 'Solid Queue eliminates Redis for background jobs', 'Kamal deployment is a game changer', 'Rails 8's authentication generator creates secure auth in seconds'"
  }

  AI_RESPONSE_TEMPLATES = {
    rails_tip: [
      "AI_CONTENT_PLACEHOLDER\n\nJust implemented this in my railsui.com setup 🚀",
      "Rails discovery: AI_CONTENT_PLACEHOLDER\n\nWish I knew this sooner for railsui.com",
      "AI_CONTENT_PLACEHOLDER\n\nThis is why I love Rails 8 development",
      "Found this gem: AI_CONTENT_PLACEHOLDER\n\nAlready using it in railsui.com",
      "AI_CONTENT_PLACEHOLDER\n\nMy new go-to pattern"
    ],
    tailwind_tip: [
      "CSS realization: AI_CONTENT_PLACEHOLDER\n\nUsing this in all my railsui.com components now",
      "AI_CONTENT_PLACEHOLDER\n\nGame changer for my design system",
      "Tailwind moment: AI_CONTENT_PLACEHOLDER\n\nWhy didn't I know this earlier?",
      "AI_CONTENT_PLACEHOLDER\n\nThis combo makes railsui.com components so much cleaner ✨"
    ],
    ui_insight: [
      "UX insight: AI_CONTENT_PLACEHOLDER\n\nChanged how I approach every railsui.com design",
      "AI_CONTENT_PLACEHOLDER\n\nThis thinking transformed my components",
      "Design truth: AI_CONTENT_PLACEHOLDER\n\nLearned this building railsui.com",
      "AI_CONTENT_PLACEHOLDER\n\nWhy I rebuilt half my design system"
    ],
    building_public: [
      "Building railsui.com: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER\n\nThe reality of shipping as a solo dev 🛠️",
      "Product lesson: AI_CONTENT_PLACEHOLDER\n\nLearned this the hard way",
      "AI_CONTENT_PLACEHOLDER\n\nNo one talks about this part of building"
    ],
    rails_8_feature: [
      "Rails 8: AI_CONTENT_PLACEHOLDER\n\nAlready loving this in my railsui.com setup",
      "AI_CONTENT_PLACEHOLDER\n\nRails 8 is changing how I build everything",
      "Rails 8 gem: AI_CONTENT_PLACEHOLDER\n\nExactly what I needed",
      "AI_CONTENT_PLACEHOLDER\n\nWhy I'm excited about Rails 8"
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

    # Initialize OpenAI client
    if ENV['OPENAI_API_KEY']
      @openai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    else
      puts "⚠️  No OpenAI API key found. Using fallback content only."
      @openai_client = nil
    end
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

  def generate_ai_content(content_type)
    return nil unless @openai_client

    begin
      response = @openai_client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content: "You are an experienced Rails developer who builds and shares practical development insights. Always respond in first person with authentic developer voice. Be concise, practical, and enthusiastic about Rails 8 and modern web development."
            },
            {
              role: "user",
              content: AI_PROMPTS[content_type]
            }
          ],
          max_tokens: 100,
          temperature: 0.8
        }
      )

      content = response.dig("choices", 0, "message", "content")&.strip

      # Clean up the content
      content = content.gsub(/^["']|["']$/, '') if content # Remove quotes
      content = content.gsub(/\n+/, ' ') if content # Remove newlines

      content
    rescue => e
      puts "⚠️  AI generation failed: #{e.message}"
      nil
    end
  end

  def generate_post
    # Choose content type
    content_type = AI_RESPONSE_TEMPLATES.keys.sample

    # Try AI generation first
    ai_content = generate_ai_content(content_type)

    if ai_content && !ai_content.empty?
      # Use AI-generated content
      template = AI_RESPONSE_TEMPLATES[content_type].sample
      formatted_post = template.gsub('AI_CONTENT_PLACEHOLDER', ai_content)
      source = "AI"
    else
      # Fall back to preset content
      template_group = FALLBACK_TEMPLATES.find { |t| t[:type] == content_type }
      if template_group
        template = template_group[:templates].sample
        content = FALLBACK_CONTENT[content_type].sample
        formatted_post = template.gsub('CONTENT_PLACEHOLDER', content)
        source = "Fallback"
      else
        formatted_post = "Rails 8 is amazing for building modern web apps!\n\nLiving it at railsui.com 🚀"
        source = "Default"
      end
    end

    # Ensure tweet is under 280 characters
    if formatted_post.length > 280
      # Trim content while preserving the template structure
      excess = formatted_post.length - 277
      lines = formatted_post.split("\n")
      if lines.length > 1
        # Trim the first line (usually the content)
        lines[0] = lines[0][0..-(excess + 4)] + "..."
        formatted_post = lines.join("\n")
      else
        formatted_post = formatted_post[0..276] + "..."
      end
    end

    puts "📝 Generated using: #{source}" if ENV['DEBUG']
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
    puts "AI available: #{@openai_client ? 'YES' : 'NO (using fallback content)'}"

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

    puts "AI available: #{@openai_client ? 'YES' : 'NO (using fallback content)'}"
    puts "Content types: #{AI_RESPONSE_TEMPLATES.keys.join(', ')}"
    puts "Fallback content items: #{FALLBACK_CONTENT.values.flatten.length}"
  end

  def test_ai
    puts "🤖 Testing AI content generation:"
    puts "=" * 40

    AI_PROMPTS.each do |type, prompt|
      puts "\n#{type.to_s.upcase}:"
      puts "Prompt: #{prompt[0..100]}..."

      ai_content = generate_ai_content(type)
      if ai_content
        template = AI_RESPONSE_TEMPLATES[type].sample
        formatted = template.gsub('AI_CONTENT_PLACEHOLDER', ai_content)
        puts "Generated: #{formatted}"
        puts "Length: #{formatted.length}/280"
      else
        puts "❌ Failed to generate AI content"
      end
    end
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
  when 'test-ai'
    poster.test_ai
  else
    puts "Usage:"
    puts "  ruby auto_poster.rb demo     # Show what would be posted"
    puts "  ruby auto_poster.rb status   # Show posting status"
    puts "  ruby auto_poster.rb post     # Post if it's time"
    puts "  ruby auto_poster.rb test-ai  # Test AI generation"
    puts ""
    puts "Running demo by default..."
    poster.demo_run
  end
end
