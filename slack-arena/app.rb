module SlackArena
  class App < SlackRubyBotServer::App
    include Celluloid

    def after_start!
      once_and_every 60 * 60 * 24 do
        expire_subscriptions!
        deactivate_asleep_teams!
        check_trials!
        check_subscribed_teams!
      end
      once_and_every 2 * 60 do
        sync!
      end
      once_and_every 60 * 60 do
        ping_teams!
      end
    end

    private

    def log_info_without_repeat(message)
      return if message == @log_message
      @log_message = message
      logger.info message
    end

    def once_and_every(tt)
      yield
      every tt do
        yield
      end
    end

    def ping_teams!
      Team.active.each do |team|
        begin
          ping = team.ping!
          next if ping[:presence].online
          logger.warn "DOWN: #{team}"
          after 60 do
            ping = team.ping!
            unless ping[:presence].online
              logger.info "RESTART: #{team}"
              SlackStrava::Service.instance.start!(team)
            end
          end
        rescue StandardError => e
          logger.warn "Error pinging team #{team}, #{e.message}."
        end
      end
    end

    def check_trials!
      log_info_without_repeat "Checking trials for #{Team.active.trials.count} team(s)."
      Team.active.trials.each do |team|
        logger.info "Team #{team} has #{team.remaining_trial_days} trial days left."
        next unless team.remaining_trial_days > 0 && team.remaining_trial_days <= 3
        team.inform_trial!
      rescue StandardError => e
        logger.warn "Error checking team #{team} trial, #{e.message}."
      end
    end

    def expire_subscriptions!
      log_info_without_repeat "Checking subscriptions for #{Team.active.count} team(s)."
      Team.active.each do |team|
        next unless team.subscription_expired?
        team.subscription_expired!
      rescue StandardError => e
        backtrace = e.backtrace.join("\n")
        logger.warn "Error in expire subscriptions cron for team #{team}, #{e.message}, #{backtrace}."
      end
    end

    def sync!
      log_info_without_repeat "Checking channels for #{Team.active.count} team(s)."
      Team.active.each do |team|
        next if team.subscription_expired?
        team.arena_feeds.each(&:sync_new_arena_items!)
      rescue StandardError => e
        backtrace = e.backtrace.join("\n")
        logger.warn "Error in cron for team #{team}, #{e.message}, #{backtrace}."
      end
    end

    def deactivate_asleep_teams!
      log_info_without_repeat "Checking inactivity for #{Team.active.count} team(s)."
      Team.active.each do |team|
        next unless team.asleep?
        begin
          team.deactivate!
          team.inform_everyone!(text: "Your subscription expired more than 2 weeks ago, deactivating. Reactivate at #{SlackArena::Service.url}. Your data will be purged in another 2 weeks.")
        rescue StandardError => e
          logger.warn "Error informing team #{team}, #{e.message}."
        end
      end
    end

    def check_subscribed_teams!
      logger.info "Checking Stripe subscriptions for #{Team.striped.count} team(s)."
      Team.striped.each do |team|
        customer = Stripe::Customer.retrieve(team.stripe_customer_id)
        customer.subscriptions.each do |subscription|
          subscription_name = "#{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)})"
          logger.info "Checking #{team} subscription to #{subscription_name}, #{subscription.status}."
          case subscription.status
          when 'past_due'
            logger.warn "Subscription for #{team} is #{subscription.status}, notifying."
            team.inform_everyone!(text: "Your subscription to #{subscription_name} is past due. #{team.update_cc_text}")
          when 'canceled', 'unpaid'
            logger.warn "Subscription for #{team} is #{subscription.status}, downgrading."
            team.inform_everyone!(text: "Your subscription to #{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)}) was canceled and your team has been downgraded. Thank you for being a customer!")
            team.update_attributes!(subscribed: false)
          end
        end
      end
    end
  end
end
