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
        "CONTENT_PLACEHOLDER\n\nJust used this pattern in my latest railsui.com component 🚀",
        "Rails tip: CONTENT_PLACEHOLDER\n\nSaved me hours while building railsui.com templates",
        "CONTENT_PLACEHOLDER\n\nThis is why I love Rails development so much"
      ]
    },
    {
      type: :tailwind_tip,
      templates: [
        "Tailwind discovery: CONTENT_PLACEHOLDER\n\nUsing this in all my railsui.com components now",
        "CONTENT_PLACEHOLDER\n\nGame changer for my railsui.com design system"
      ]
    },
    {
      type: :ui_insight,
      templates: [
        "UI realization: CONTENT_PLACEHOLDER\n\nChanged how I approach every railsui.com design",
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
    rails_tip: "Write a casual Rails tip like you're texting a dev friend. Be specific about a real problem you solved. Avoid: 'game changer', 'boost', 'leverage', 'seamless', 'streamline', 'elevate'. Use simple words. Sound frustrated or excited about something concrete. Under 180 chars. Examples: 'Spent 2 hours debugging N+1 queries. `includes` fixed it instantly', 'Rails 8 auth generator saved my weekend. No more Devise config hell', 'Finally figured out Turbo morphing. My forms feel snappy now'",

    tailwind_tip: "Write a Tailwind tip like you just discovered something cool while coding. Be specific about what you were building. Avoid marketing speak. Sound like you're sharing a quick win. Under 180 chars. Examples: 'Was fighting with flexbox alignment. `items-center justify-between` solved it in 5 seconds', 'Discovered `space-y-4` yesterday. Deleted 20 lines of margin CSS', 'TIL: `prose` class makes my blog posts look decent without trying'",

    ui_insight: "Share a UI realization like you just had an 'aha' moment. Be specific about user behavior you observed. Avoid design jargon. Sound like you learned something from real users. Under 180 chars. Examples: 'Watched users struggle with our form. Inline errors > alert boxes', 'Users ignored our fancy sidebar. Put key stuff in the header instead', 'Loading spinners feel slow. Skeleton screens make it seem faster'",

    building_public: "Share an honest moment from building your product. Be vulnerable about mistakes or surprises. Avoid startup clichés. Sound tired but determined. Under 180 chars. Examples: 'Spent 3 days on perfect animations. Users care more about fast load times', 'Thought my feature was brilliant. 5 users tested it. 5 users confused by it', 'Shipped a broken search. Fixed it in 2 hours. Nobody even noticed'",

    rails_8_feature: "Share excitement about Rails 8 like you just tried something new. Be specific about your setup or what changed. Avoid hype words. Sound like you're recommending to a friend. Under 180 chars. Examples: 'Tried Solid Queue today. Deleted my Redis config. One less thing to worry about', 'Rails 8 auth is stupid simple. Generated working login in 30 seconds', 'Kamal deployed my app faster than I deploy to Heroku. Wild'"
  }

  AI_RESPONSE_TEMPLATES = {
    rails_tip: [
      "AI_CONTENT_PLACEHOLDER\n\nJust tried this on railsui.com. Works like a charm",
      "TIL: AI_CONTENT_PLACEHOLDER\n\nWish I knew this months ago",
      "AI_CONTENT_PLACEHOLDER\n\nThis is why I love Rails so much",
      "AI_CONTENT_PLACEHOLDER\n\nAlready using this everywhere in railsui.com",
      "AI_CONTENT_PLACEHOLDER\n\nMy new favorite Rails trick"
    ],
    tailwind_tip: [
      "AI_CONTENT_PLACEHOLDER\n\nUsing this in all my railsui.com components now",
      "AI_CONTENT_PLACEHOLDER\n\nMakes my CSS so much cleaner",
      "AI_CONTENT_PLACEHOLDER\n\nWhy didn't I think of this earlier?",
      "AI_CONTENT_PLACEHOLDER\n\nThis combo makes railsui.com components look way better ✨"
    ],
    ui_insight: [
      "AI_CONTENT_PLACEHOLDER\n\nChanged how I approach every railsui.com design",
      "AI_CONTENT_PLACEHOLDER\n\nThis thinking transformed my components",
      "AI_CONTENT_PLACEHOLDER\n\nLearned this building railsui.com",
      "AI_CONTENT_PLACEHOLDER\n\nWhy I rebuilt half my design system"
    ],
    building_public: [
      "Building railsui.com: AI_CONTENT_PLACEHOLDER",
      "AI_CONTENT_PLACEHOLDER\n\nThe reality of shipping solo 🛠️",
      "AI_CONTENT_PLACEHOLDER\n\nLearned this the hard way",
      "AI_CONTENT_PLACEHOLDER\n\nNo one warns you about this part"
    ],
    rails_8_feature: [
      "AI_CONTENT_PLACEHOLDER\n\nLoving this in my railsui.com setup",
      "AI_CONTENT_PLACEHOLDER\n\nRails 8 is wild",
      "AI_CONTENT_PLACEHOLDER\n\nThis is exactly what I needed",
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
              content: "You are a tired but passionate Rails developer sharing quick thoughts with other devs. Write like you're texting a friend, not writing marketing copy. Use simple words. Be specific about actual problems you solved. Avoid: 'game changer', 'leverage', 'seamless', 'streamline', 'elevate', 'boost', 'harness', 'unlock', 'empower', 'robust', 'scalable', 'cutting-edge'. Include mild frustration or excitement about concrete things. Sound human, not like an AI trying to sound human."
            },
            {
              role: "user",
              content: AI_PROMPTS[content_type]
            }
          ],
          max_tokens: 120,
          temperature: 1.1,
          frequency_penalty: 0.3,
          presence_penalty: 0.2
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
        formatted_post = "Rails 8 is amazing for building modern web apps! 🚀"
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
