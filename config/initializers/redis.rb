# frozen_string_literal: true
r_file = Rails.root.join('config', 'redis.yml').to_s
r_config = YAML.safe_load(File.open(r_file)).deep_symbolize_keys![Rails.env.to_sym]
# TODO: this is depricated figure out replacement
# Dropped support for this in hryax 5
Redis.current = Redis.new(r_config.merge(thread_safe: true))
