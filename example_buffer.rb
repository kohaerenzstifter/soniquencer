# Welcome to Sonic Pi

use_arg_checks false
require "/share/soniquencer.git/soniquencer.rb"

$bpm = 115
$shuffleswing_factor = 1
$shuffleswing_at = 8
$nr_steps_per_bar = 256

$triggers=16
$note_length=1
$num_octaves=1
$instrument=:tb303

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
      Tb303.new(
        instrument: :tb303,
        # id must be unique across all synths!!!
        id: "dssd",
        accent_amp: 0.0000025,
        accent_cutoff: 15,
        value:
         (ring
            Tb303::Step.new(
              triggers: $triggers,
              ons: (ring true).shuffle,
              glides: (ring false, false,true),
              accents: (ring false,true,false,false,false).shuffle,
              properties: {
                note: (chord_degree :i, :C2, :minor, 9)
                #note: chord(:C3, :i7, num_octaves:1).shuffle,
              }
            )
          ),
        defaults:
          Tb303::Defaults.new(
            properties: {
              note_slide: 0.5,
              cutoff: 60,
              resonance: 0,
              amp: 0.000002
            }
          ),
          note_length: $note_length
        ),

      Tb303.new(
        instrument: $instrument,
        # id must be unique across all synths!!!
        id: "wew",
        accent_amp: 0.0000025,
        accent_cutoff: 15,
        value:
         (ring
            Tb303::Step.new(
              triggers: $triggers,
              ons: (ring true).shuffle,
              glides: (ring false, true, false),
              accents: (ring false,false,false,false,true).shuffle,
              properties: {
                note: (chord_degree :i, :C2, :minor, 5)
                #note: chord(:C2, :i7, num_octaves:$num_octaves).shuffle,
              }
            )
          ),
        defaults:
          Tb303::Defaults.new(
            properties: {
              note_slide: 0.5,
              cutoff: 60,
              resonance: 0,
              amp: 0.0000025
            }
          ),
          note_length: $note_length
        ),
#      Synth.new(
#        instrument: $instrument,
#        # id must be unique across all synths!!!
#        id: "örfjöweköew",
#        value:
#         (ring
#            Synth::Step.new(
#              triggers: $triggers,
#              ons: (ring true).shuffle,
#              glides: (ring false, true, false),
#              properties: {
#                note: chord(:C4, :i7, num_octaves:$num_octaves).shuffle,
#                amp: (ring 0.6,0.6,1,0.6,0.6).shuffle,
#                cutoff: (ring 60,60,60,60,60,60,85).shuffle
#              }
#            )
#          ),
#        defaults:
#          Synth::Defaults.new(
#            properties: {
#              note_slide: 0.5,
#              cutoff: 80,
#              amp: 0.0000025
#            }
#          ),
#          note_length: $note_length
#        ),
#      Synth.new(
#        instrument: $instrument,
#        # id must be unique across all synths!!!
#        id: "rejföökf",
#        value:
#         (ring
#            Synth::Step.new(
#              triggers: $triggers,
#              ons: (ring true).shuffle,
#              glides: (ring false, true, false),
#              properties: {
#                note: chord(:C3, :i7, num_octaves:$num_octaves).shuffle,
#                amp: (ring 0.6,0.6,1,0.6,0.6).shuffle,
#                cutoff: (ring 60,60,60,60,60,60,85).shuffle
#              }
#            )
#          ),
#        defaults:
#          Synth::Defaults.new(
#            properties: {
#              note_slide: 0.5,
#              cutoff: 80,
#              amp: 0.0000025
#            }
#          ),
#          note_length: $note_length
#        ),

#      Synth.new(
#        instrument: $instrument,
#        # id must be unique across all synths!!!
#        id: "fmslfds",
#        value:
#         (ring
#            Synth::Step.new(
#              triggers: $triggers,
#              ons: (ring true).shuffle,
#              glides: (ring false, true, false),
#              properties: {
#                note: chord(:C2, :i7, num_octaves:$num_octaves).shuffle,
#                amp: (ring 0.6,0.6,1,0.6,0.6).shuffle,
#                cutoff: (ring 60,60,60,60,60,60,85).shuffle
#              }
#            )
#          ),
#        defaults:
#          Synth::Defaults.new(
#            properties: {
#              note_slide: 0.5,
#              cutoff: 80,
#              amp: 0.0000025
#            }
#          ),
#          note_length: $note_length
#        ),
#      #ControlFx.new(idx: 0, name: "mix", value: (ring 0.2), note_length: 1),
      ControlFx.new(idx: 1, name: "mix", value: (ring 0.1), note_length: 1),
      ControlFx.new(idx: 2, name: "distort", value: (ring 0.9), note_length: 1),
      ControlFx.new(idx: 2, name: "amp", value: (ring 0.035), note_length: 1),
#     ControlFx.new(idx: 1, name: "phase", value: (ring 0.5), note_length: 1),
      ControlFx.new(idx: 0, name: "cutoff", value: (ring 50,60,70,80,90,100).shuffle, note_length: 4),
      ControlFx.new(idx: 0, name: "res", value: (ring 0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1), note_length: 2),
  ])
end

in_thread(name: :steps_thread) do
  sleep 0.5
  idx = 0
  sleeps = []
  with_fx :nrlpf do |f|
    with_fx :ping_pong do |e|
      with_fx :distortion do |d|
        effects = [f,e,d]
        loop do
          sleeps = do_steps_thread(idx, get_definitions(), sleeps, effects, true)
          idx = idx + 1
        end
      end
    end
  end
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
        Sample.new(value: (ring Sample::Step.new(triggers: 16, ons: (ring
        true, false, false, false,
        true, false, false, false,
        true, false, false, true,
        false, false, false, false), properties: { rate: (ring 1), amp: (ring 1) })),
        note_length: 1, sample_dir: "~/sonic-pi/etc/samples", sample_xp: "bd_", sample_idx: 5),
#        # closed hihat
      Sample.new(value: (ring 0, 1, Sample::Step.new(triggers: 16, properties: { amp: (ring 1, 0.5, 0.1).shuffle } )),
                 note_length: 1, sample_dir: "/share/waveland1/HIHAT", sample_xp: "", sample_idx: 16,
                 defaults: Sample::Defaults.new( properties: { amp: 0.2, rate: 0.9 } )),
#      # open hihat
      Sample.new(value: (ring 0,0,1,0,
                              0,0,1,0,
                              0,0,1,0,
                              0,1,0,1
), note_length: 16, sample_dir: "/share/waveland1/HIHAT", sample_xp: "", sample_idx: 24,
                 defaults: Sample::Defaults.new(properties: { amp: 0.4 } )),
      ControlFx.new(idx: 0, name: "mix", value: (ring 0.1,0.2,0.3,0.4,0.5,0.6).shuffle, note_length: 4),
      ControlFx.new(idx: 0, name: "room", value: (ring 0.1,0.2,0.3,0.4,0.5,0.6).shuffle, note_length: 4),
  ])
end

in_thread(name: :steps_thread1) do
   sleep 0.5
   idx = 0
   sleeps = []
   with_fx :reverb do |r|
     loop do
       effects = [r]
       sleeps = do_steps_thread(idx, get_definitionsX(), sleeps, effects, false)
       idx = idx + 1
     end
   end
 end
