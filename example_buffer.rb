# Welcome to Sonic Pi

use_arg_checks false
require "/share/soniquencer.git/soniquencer.rb"

$bpm = 110
$shuffleswing_factor = 1
$shuffleswing_at = 8
$nr_steps_per_bar = 256

$offset=6
$ofset=3
$triggers=4
$release=3
$note_length=4
$num_octaves=1

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
      Synth.new(
        instrument: :tb303,
        # id must be unique across all synths!!!
        id: "fmslfds",
        value:
          (ring
            Synth::Step.new(
              triggers: $triggers,
              ons: (ring true),
              properties: {
                note: chord(:E1, :madd13, num_octaves:$num_octaves).shuffle,
                gleit: (ring false)
              }
            ),
          ),
        defaults:
          Sample::Defaults.new(
            properties: {
              cutoff_release: $release,
              release: $release,
              note_slide: 0.5,
              cutoff: 80,
              amp: 0.1
            }
          ),
          note_length: $note_length
        ),
      #Synth.new(
      #  instrument: :hoover,
      #  # id must be unique across all synths!!!
      #  id: "fmslfds",
      #  value: (ring
      #          Synth::Step.new(triggers: $triggers, properties: { note: chord(:E5, :madd13, num_octaves:$num_octaves).shuffle, on: (ring true), gleit: (ring false, true, true, true, false) } ),
      #          ),
      #  defaults: Sample::Defaults.new( properties: { cutoff_release: $release, release: $release, note_slide: 0.5, cutoff: 80, amp: 0.1 } ),
      #  note_length: $note_length),
      #Synth.new(
      #  instrument: :hoover,
      #  # id must be unique across all synths!!!
      #  id: "dsfds",
      #  value: (ring
      #          Synth::Step.new(triggers: $triggers, properties: { note: chord(:E5+7, :madd13, num_octaves:$num_octaves).shuffle, on: (ring true), gleit: (ring false, true, true, true, false) } ),
      #          ),
      #  defaults: Sample::Defaults.new( properties: { cutoff_release: $release, release: $release, note_slide: 0.5, cutoff: 80, amp: 0.1 } ),
      #  note_length: $note_length),
      #Synth.new(
      #  instrument: :hoover,
      #  # id must be unique across all synths!!!
      #  id: "dsfdss",
      #  value: (ring
      #          Synth::Step.new(triggers: $triggers, properties: { note: chord(:E5-3, :madd13, num_octaves:$num_octaves).shuffle, on: (ring true), gleit: (ring false, true, true, true, false) } ),
      #          ),
      #  defaults: Sample::Defaults.new( properties: { cutoff_release: $release, release: $release, note_slide: 0.5, cutoff: 80, amp: 0.1 } ),
      #  note_length: $note_length),
      ControlFx.new(idx: 0, name: "mix", value: (ring 0.1), note_length: 1),
      ControlFx.new(idx: 1, name: "mix", value: (ring 0.05), note_length: 1),
      ControlFx.new(idx: 1, name: "phase", value: (ring 0.5), note_length: 1),
      ControlFx.new(idx: 0, name: "cutoff", value: (ring 40,60,80,100,120,100,80,60), note_length: 8),
      ControlFx.new(idx: 0, name: "res", value: (ring 0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1), note_length: 4),
      # base drum
      #Sample.new(value: (ring Sample::Step.new(triggers: 1, properties: { rate: (ring 1), amp: (ring 1) }, ons: (ring true))),
      #           note_length: 4, sample_dir: "~/sonic-pi/etc/samples", sample_xp: "bd_", sample_idx: 5),
      # snare drum
      #Sample.new(value: (ring Sample::Step.new(triggers: 4, ons: (ring false, true), properties: { amp: (ring 0.05) } )),
      #           note_length: 1, sample_dir: "~/sonic-pi/etc/samples", sample_xp: "sn_", sample_idx: 1),
      # closed hihat
      #Sample.new(value: (ring 0, 1, 0, 1, 0, 1, 0, Sample::Step.new(triggers: 4, properties: { amp: (ring 1, 0.5, 0.1) } )),
      #           note_length: 8, sample_dir: "/share/waveland1/HIHAT", sample_xp: "", sample_idx: 16,
      #           defaults: Sample::Defaults.new( properties: { amp: 1, rate: 0.9 } )),
      # open hihat
      #Sample.new(value: (ring 1, 0, 0, 0, 1, 0), note_length: 4, sample_dir: "/share/waveland1/HIHAT", sample_xp: "", sample_idx: 18,
      #           defaults: Sample::Defaults.new(properties: { amp: 0.5 } )),
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
      Sample.new(value: (ring Sample::Step.new(triggers: 3, properties: { rate: (ring 1), amp: (ring 1, 0.3, 0.3) }, ons: (ring false, true, true))),
                 note_length: 4, sample_dir: "~/sonic-pi/etc/samples", sample_xp: "bd_",sample_idx: 1)
  ])
end

in_thread(name: :steps_thread) do
  sleep 0.5
  idx = 0
  sleeps = []
  with_fx :nrlpf do |f|
    with_fx :ping_pong do |e|
      effects = [f,e]
      loop do
        sleeps = do_steps_thread(idx, get_definitions(), sleeps, effects, true)
        idx = idx + 1
      end
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
