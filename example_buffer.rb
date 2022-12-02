# Welcome to Sonic Pi

require "/share/soniquencer.git/soniquencer.rb"

$bpm = 100
$shuffleswing_factor = 1.2
$shuffleswing_at = 16
$nr_steps_per_bar = 256

define :get_definitions do ||
  return Definitions.new(
    bpm: $bpm,
    # 0.0 < value < 2, 1.0 means no swing or shuffle
    shuffleswing_factor: $shuffleswing_factor,
    # value = 2^x, x \in N
    shuffleswing_at: $shuffleswing_at,
    # must be a power of 2, never modify during playback!
    nr_steps_per_bar: $nr_steps_per_bar,
    patterns: [
      # ControlFx.new(idx: 0, mixes: (ring 0.0, 0.5, 0.25, 1.0, 0.75), note_length: 128),
      ControlFx.new(idx: 0, name: "cutoff", value: (ring 0,20,40,60,80,100,120,100,80,60,40,20), note_length: 8),
      ControlFx.new(idx: 0, name: "res", value: (ring 0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1), note_length: 8),
      # base drum
      #Sample.new(value: (ring SampleStep.new(triggers: 1, rate: (ring 30), properties: { amp: (ring 0.5) } ),
      #                   SampleStep.new(triggers: 1, properties: { amp: (ring 0.5), rate: (ring 15) } ),
      #                   SampleStep.new(triggers: 1, properties: { amp: (ring 0.5), rate: (ring 15) } ),
      #                   SampleStep.new(triggers: 1, properties: { amp: (ring 0.5), rate: (ring 15) } )),
      #           note_length: 4, sample_dir: "~/sonic-pi/etc/samples", sample_xp: "bd_",sample_idx: 1),
      Sample.new(value: (ring SampleStep.new(triggers: 1, properties: { rate: (ring 1), amp: (ring 1) }, ons: (ring true))),
                 note_length: 4, sample_dir: "~/sonic-pi/etc/samples", sample_xp: "bd_", sample_idx: 1),
      # snare drum
      Sample.new(value: (ring 0, 1, 0, 2, 0, SampleStep.new(triggers: 3, properties: { amp: (ring 0.1, 1, 0.5) } )),
                 note_length: 4, sample_dir: "~/sonic-pi/etc/samples", sample_xp: "sn_", sample_idx: 1),
      # closed hihat
      Sample.new(value: (ring 0, 1, 0, 1, 0, 1, 0, SampleStep.new(triggers: 4, properties: { amp: (ring 1, 0.5, 0.1) } )),
                 note_length: 8, sample_dir: "/share/waveland1/HIHAT", sample_xp: "", sample_idx: 16,
                 defaults: SampleDefaults.new( properties: { amp: 1, rate: 0.9 } )),
      # open hihat
      Sample.new(value: (ring 1, 0, 0, 0, 1, 0), note_length: 4, sample_dir: "/share/waveland1/HIHAT", sample_xp: "", sample_idx: 18,
                 defaults: SampleDefaults.new(properties: { amp: 0.5 } )),
      #Synth.new((ring 54,"",59,61,"",51,""), 16)
  ])
end

define :get_definitionsX do ||
  return Definitions.new(
    bpm: $bpm,
    # 0.0 < value < 2, 1.0 means no swing or shuffle
    shuffleswing_factor: $shuffleswing_factor,
    # value = 2^x, x \in N
    shuffleswing_at: $shuffleswing_at,
    # must be a power of 2, never modify during playback!
    nr_steps_per_bar: $nr_steps_per_bar,
    patterns: [
      # base drum
      Sample.new(value: (ring SampleStep.new(triggers: 3, properties: { rate: (ring 1), amp: (ring 1, 0.3, 0.3) }, ons: (ring false, true, true))),
                 note_length: 4, sample_dir: "~/sonic-pi/etc/samples", sample_xp: "bd_",sample_idx: 1)
  ])
end

in_thread(name: :steps_thread) do
  sleep 0.5
  idx = 0
  sleeps = []
  with_fx :nrlpf do |r|
    effects = [r]
    loop do
      sleeps = do_steps_thread(idx, get_definitions(), sleeps, effects, true)
      idx = idx + 1
    end
  end
end

##| in_thread(name: :steps_thread1) do
##|   sleep 0.5
##|   idx = 0
##|   sleeps = []
##|   with_fx :reverb do |r|
##|     loop do
##|       sleeps = do_steps_thread(idx, get_definitionsX(), sleeps, [], false)
##|       idx = idx + 1
##|     end
##|   end
##| end
