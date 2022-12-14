class Instrument
  class Step
    attr_reader :triggers
    attr_accessor :ons
    attr_accessor :properties
    def initialize(**args)
      @triggers = args[:triggers]
      @ons = args[:ons]
      @properties = args[:properties]
    end
  end

  class Defaults
    attr_accessor :on
    attr_accessor :properties
    def initialize(**args)
      @on = args[:on]
      @properties = args[:properties]
    end
  end

  class Context
    attr_reader :trigger_idx
    attr_reader :step
    attr_reader :factor
    def initialize(trigger_idx, step, factor)
      @trigger_idx = trigger_idx
      @step = step
      @factor = factor
    end
  end

  attr_reader :value
  attr_reader :note_length
  attr_reader :defaults
  def initialize(**args)
    @value = args[:value]
    @note_length = args[:note_length]
    @defaults = args[:defaults]
  end

  def get_defaults()
    result = self.defaults;
    if result == nil
      result = get_defaults_object()
    end
    if result.on == nil
      result.on = true
    end
    if result.properties == nil
      result.properties = {}
    end
    result = sanitize_defaults(result);
    return result
  end

  def get_step(idx, defaults)
    result = self.value[idx]
    if result.is_a? Integer
      result = get_step_from_value(result)
    end
    if result.ons == nil
      result.ons = defaults.on != nil ? [defaults.on].ring : [true].ring
    end
    if result.properties == nil
      result.properties = defaults.properties
    else
      defaults.properties.keys.each{ |key|
        if result.properties[key] == nil
          result.properties[key] = [defaults.properties[key]].ring
        end
      }
    end
    return result
  end

  def play(outer_scope, idx, factor, sleeps, effects)
    value = get_step(idx, get_defaults())

    if value.triggers > 0
      sleeps = do_play(outer_scope, 0, value, factor, sleeps)
    end
    return sleeps
  end

  def prepareToSound(step, trigger_idx)
    result = {}
    step.properties.keys.each{ |key|
      result[key] = step.properties[key][trigger_idx]
    }
    return result
  end

  def do_play(outer_scope, trigger_idx, step, factor, sleeps)
    if step.ons[trigger_idx]
      properties = prepareToSound(step, trigger_idx)

      sound(outer_scope, properties)
    end
    if (step.triggers - trigger_idx) > 1
      sleeps = add_sleep(Callback.new(((4.0/note_length)/step.triggers) * factor, self, get_context(trigger_idx + 1, step, factor)), sleeps)
    end
    return sleeps
  end

  def callback(outer_scope, sample_context, sleeps)
    sleeps = do_play(outer_scope, sample_context.trigger_idx, sample_context.step, sample_context.factor, sleeps)
    return sleeps
  end
end

class Sample < Instrument
  attr_reader :sample_dir
  attr_reader :sample_xp
  attr_reader :sample_idx
  def initialize(**args)
    super
    @sample_dir = args[:sample_dir]
    @sample_xp = args[:sample_xp]
    @sample_idx = args[:sample_idx]
  end

  class Step < Instrument::Step
  end

  class Defaults < Instrument::Defaults
  end

  class Context < Instrument::Context
  end

  def get_defaults_object()
    return Defaults.new()
  end

  def sanitize_defaults(result)
    return result
  end

  def get_context(trigger_idx, step, factor)
    return Context.new(trigger_idx, step, factor)
  end

  def get_step_from_value(value)
    return Step.new(triggers: value)
  end

  def sound(outer_scope, properties)
    outer_scope.sample self.sample_dir, self.sample_xp, self.sample_idx, properties
  end
end

class Synth < Instrument
  attr_reader :instrument
  attr_reader :id
  def initialize(**args)
    super
    @instrument = args[:instrument]
    @id = args[:id]
    @gleit = false
  end

  class Step < Instrument::Step
    attr_accessor :gleits
    def initialize(**args)
      super
      @gleits = args[:gleits]
    end
  end

  class Defaults < Instrument::Defaults
    attr_accessor :gleit
    def initialize(**args)
      super
      @gleit = args[:gleit]
    end
  end

  class Context < Instrument::Context
  end

  def get_defaults_object()
    return Defaults.new()
  end

  def sanitize_defaults(result)
    if result.properties[:note] == nil
      result.properties[:note] = 60
    end
    if result.gleit == nil
      result.gleit = false
    end
    return result
  end

  def get_context(trigger_idx, step, factor)
    return Context.new(trigger_idx, step, factor)
  end

  def get_step(idx, defaults)
    result = super

    if result.gleits == nil
      result.gleits = defaults.gleit != nil ? [defaults.gleit].ring : [false].ring
    end

    return result
  end

  def get_step_from_value(value)
    return Step.new(triggers: value)
  end

  def prepareToSound(step, trigger_idx)
    result = super
    gleit = step.gleits[trigger_idx]
    return result
  end

  def sound(outer_scope, properties)
    gleiting = nil
    active = outer_scope.get[@id.to_sym]
    if @gleit && @id != nil
      gleiting = active
    end
    if gleiting == nil
      if @instrument != nil
        outer_scope.use_synth @instrument
      end
      if active != nil
        outer_scope.control active, amp: 0
      end
      store = outer_scope.play properties[:note], properties
      if @id != nil
        outer_scope.set @id.to_sym, store
      end
    else
      outer_scope.control gleiting, properties
    end
  end
end

ControlFx = Struct.new(:name, :value, :idx, :note_length, keyword_init: true) do
  def play(outer_scope, idx, factor, sleeps, effects)
    value = self.value[idx]
    if value >= 0 && self.idx < effects.size
      outer_scope.control(effects[self.idx], name.to_sym => value)
    end
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
