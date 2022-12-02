Sample = Struct.new(
  :value,
  :note_length,
  :sample_dir,
  :sample_xp,
  :sample_idx,
:sample_defaults, keyword_init: true) do

  SampleStep = Struct.new(:triggers, :ons, :properties, keyword_init: true)
  SampleDefaults = Struct.new(:on, :properties, keyword_init: true)

  SampleContext = Struct.new(:trigger_idx, :step, :factor)

  def get_sample_defaults()
    result = self.sample_defaults;
    if result == nil
      result = SampleDefaults.new()
    end
    if result.on == nil
      result.on = true
    end
    if result.properties == nil
      result.properties = {}
    end
    return result
  end

  def get_default_on(sample_defaults)
    result = sample_defaults.on
    if result == nil
      result = true
    end
    return result
  end

  def play(outer_scope, idx, factor, sleeps, effects)
    value = self.value[idx]
    if value.is_a? Integer
      value = SampleStep.new(triggers: value)
    end
    sample_defaults = get_sample_defaults()
    if value.ons == nil
      value.ons = [get_default_on(sample_defaults)].ring
    end
    if value.properties == nil
      value.properties = {}
    end

    sample_defaults.properties.keys.each{ |key|
      if value.properties[key] == nil
        value.properties[key] = [sample_defaults.properties[key]].ring
      end
    }

    if value.triggers > 0
      sleeps = do_play(outer_scope, 0, value, factor, sleeps)
    end
    return sleeps
  end

  def do_play(outer_scope, trigger_idx, step, factor, sleeps)
    if step.ons[trigger_idx]
      properties = {}

      step.properties.keys.each{ |key|
        properties[key] = step.properties[key][trigger_idx]
      }

      outer_scope.sample self.sample_dir, self.sample_xp, self.sample_idx, properties
    end
    if (step.triggers - trigger_idx) > 1
      sleeps = add_sleep(Callback.new(((4.0/note_length)/step.triggers) * factor, self, SampleContext.new(trigger_idx + 1, step, factor)), sleeps)
    end
    return sleeps
  end

  def callback(outer_scope, sample_context, sleeps)
    sleeps = do_play(outer_scope, sample_context.trigger_idx, sample_context.step, sample_context.factor, sleeps)
    return sleeps
  end
end

Definitions = Struct.new(
  :bpm,
  :shuffleswing_factor,
  :shuffleswing_at,
  :nr_steps_per_bar,
  :patterns,
  keyword_init: true)

Synth = Struct.new(
  :value,
:note_length) do
  def play(outer_scope, idx, factor, sleeps, effects)
    if self.value[idx].to_i.to_s == self.value[idx].to_s
      outer_scope.play self.value[idx], release: 0.15
    end
    return sleeps
  end
end

ControlFx = Struct.new(:name, :value, :idx, :note_length, keyword_init: true) do
  def play(outer_scope, idx, factor, sleeps, effects)
    value = self.value[idx]
    if value >= 0
      outer_scope.control(effects[self.idx], name.to_sym => value)
    end
    return sleeps
  end
end

def add_sleep(add_me, sleeps)
  sleeps.append(add_me)
  sleeps.sort_by!(&:time)
  return sleeps
end

Callback = Struct.new(:time, :struct, :context) do end

def steps_sleep(idx, factor, definitions, sleeps, sleeper)
  use_bpm definitions.bpm

  sleep_time = (4.0 / definitions.nr_steps_per_bar) * factor

  while (sleeps.count > 0) && (sleeps[0].time <= sleep_time)
    element = sleeps[0]
    sleep_now = element.time
    sleeps = sleeps.drop(1)
    sleep_time = sleep_time - sleep_now
    if sleep_now > 0
      sleeps.each{|el| el.time = el.time - sleep_now}
      sleep sleep_now
    end
    sleeps = element.struct.callback(self, element.context, sleeps)
  end
  if sleep_time > 0
    sleeps.each{|el| el.time = el.time - sleep_time}
    if (sleeper)
      sleep sleep_time
      cue :tick
    else
      sync :tick
    end
  end
  return sleeps
end

def perform_step(idx, pattern, factor, definitions, sleeps, effects)
  pattern_factor = definitions.nr_steps_per_bar / pattern.note_length
  if idx % pattern_factor == 0
    pattern_idx = idx / pattern_factor
    sleeps = pattern.play self, pattern_idx, factor, sleeps, effects
  end
  return sleeps
end

def do_steps_thread(idx, definitions, sleeps, effects, sleeper)
  defaultSampleStep = SampleStep.new(triggers: 1)
  nr_steps_per_bar = definitions.nr_steps_per_bar
  step_in_bar = idx % nr_steps_per_bar
  shuffleswing_factor = definitions.shuffleswing_factor
  factor = shuffleswing_factor
  if (step_in_bar / (nr_steps_per_bar / definitions.shuffleswing_at)) % 2 == 0
    factor = 2 - shuffleswing_factor
  end

  patterns = definitions.patterns
  patterns.each { |pattern| sleeps = perform_step idx, pattern, factor, definitions, sleeps, effects }
  sleeps = steps_sleep(idx, factor, definitions, sleeps, sleeper)
  return sleeps
end
