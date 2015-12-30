#$: << '/home/emily/Software/SonicPi/sonic-pi/app/server/vendor/mini_kanren/lib'
require 'mini_kanren'

################# USER PARAMETERS #################
key = nil # [:c, :major]
scale_range = nil # [:c3, :c6] # inclusive
time_sig = "4/4"
num_voices = 4
chord_progression = [:I, :IV, :V, :I]
probabilities = [0.25, 0.25, 0.25, 0.2, 0.05]
###################################################

########### SYSTEM GENERATED PARAMETERS ###########
concrete_scale = nil
###################################################

########### DO VALIDATION ON PARAMETERS ###########
# TODO: Check that notes given are valid, and return if they are not
# TODO: Make whole thing into a procedure so that this is possible
if (key != nil && key.length != 2) || (key != nil && key[0] == nil)
  puts "Invalid input: key #{ key }."
end
if scale_range != nil && scale_range.length != 2
  puts "Invalid input: range #{ scale_range }."
end
if time_sig == "4/4" && num_voices > 4
  puts "Invalid input: the number of voices cannot be more than 4 for a piece in 4/4 time."
elsif time_sig == "3/4" && num_voices > 3
  puts "Invalid input: the number of voices cannot be more than 3 for a piece in 3/4 time."
elsif time_sig != "3/4" && time_sig != "4/4" && time_sig != nil
  puts "Invalid time signature: #{ time_sig }."
end
# TODO: add validation to check that the chord progression has the right number of chords in
###################################################

################## PROCESS INPUT ##################
if scale_range!= nil
  scale_range = [note(scale_range[0]), note(scale_range[1])]
end
if time_sig == "3/4"
  time_sig = [3,4]
elsif time_sig == "4/4"
  time_sig = [4,4]
end
###################################################

############## SET THE CONCRETE SCALE #############
def get_concrete_scale(key, scale_range)
  # If key is not given, choose one at random
  if key == nil
    tonic = [:c, :cs, :d, :ds, :e, :f, :fs, :g, :gs, :a, :bs, :b].choose
    type = [:major, :minor].choose
    key = [tonic, type]
  end

  # If range is not given, default to entire scale from :c3 to :c6
  # If part of range is given, set the other to :c3/:c6 as appropriate
  if scale_range == nil
    scale_range = [note(:c3), note(:c6)]
  else
    if scale_range[0] == nil
      scale_range[0] = note(:c3)
    end
    if scale_range[1] == nil
      scale_range[1] = note(:c6)
    end
  end

  # Find the highest tonic lower than the lower limit
  min_tonic = note(key[0])
  while scale_range[0] < min_tonic
    min_tonic -= 12
  end

  # Find the lowest tonic higher than the upper limit
  max_tonic = note(key[0])
  while scale_range[1] > max_tonic
    max_tonic += 12
  end

  # Get the scale between those tonics
  num_octaves = (max_tonic - min_tonic) / 12
  concrete_scale = scale(min_tonic, key[1], num_octaves: num_octaves)

  # Convert to an array and trim to range
  concrete_scale = concrete_scale.to_a
  concrete_scale.delete_if { |note| (scale_range[0] != nil && note < scale_range[0]) || (scale_range[1] != nil && note > scale_range[1]) }

  # return a hash map containing the scale and other information in case it's been newly generated
  return {concrete_scale: concrete_scale, key: key, scale_range: scale_range}
end

# Call the function, and set the properties returned
concrete_scale_data = get_concrete_scale(key, scale_range)
concrete_scale = concrete_scale_data[:concrete_scale]
key = concrete_scale_data[:key]
scale_range = concrete_scale_data[:scale_range]
###################################################

########### GENERATE CHORD PROGRESSION ############
# If the chords have NOT already been given, then generate them.
if chord_progression == nil
  # If no time signature has been given either then generate one at random
  if time_sig == nil
    time_sig == [[3,4],[4,4]].choose
  end

  # Create a new array with a chord for each beat
  chord_progression = Array.new(time_sig[0])
  # Choose each chord at random except the last two which are always IV-I or V-I (plagal or perfect cadence)
  for i in 0..chord_progression.length - 3
    chord_progression[i] = chord_choice.choose
  end
  chord_progression[chord_progression.length - 2] = [:IV, :V].choose
  chord_progression[chord_progression.length - 1] = :I
end
###################################################

############ GET EMPTY CANON STRUCTURE ############



###################################################

# Get the root notes by choosing ones from the chords
def names_to_notes(name, scale_ring)
  case name
  when :I
    [scale_ring[1], scale_ring[3], scale_ring[5]].choose
  when :IV
    [scale_ring[4], scale_ring[6], scale_ring[8]].choose
  when :V
    [scale_ring[5], scale_ring[7], scale_ring[9]].choose
  when :VI
    [scale_ring[6], scale_ring[8], scale_ring[10]].choose
  else
    puts "Error: no name matches!"
  end
end

# Get number of voices
num_voices = rrand_i(2,4)

root_notes = Array.new(num_voices)

for i in 0..root_notes.length - 1
  root_notes[i] = Array.new(chords.length)
  for j in 0..chords.length - 1
    if (i == root_notes.length && j == root_notes[i].length)
      root_notes[i][j] = $scale_ring[0]
    else
      root_notes[i][j] = names_to_notes(chords[j], $scale_ring)
    end
  end
end

puts root_notes

# Generate the canon structure
canon = Array.new(root_notes.length)
for i in 0..canon.length - 1
  canon[i] = Array.new(root_notes[i].length)
  for j in 0..root_notes[i].length - 1
    canon[i][j] = {root_note: root_notes[i][j], rhythm: nil, notes: nil}
  end
end

puts canon
###################################################


canon_results = MiniKanren.exec do

  ################### DEFINE FUNCTIONS ###################

  # Given two notes in the scale, find the median between them (rounded down if the median is between two values)
  def find_median_note(note, next_note)
    index_of_note = $scale_ring.index(note)
    index_of_next_note = $scale_ring.index(next_note)

    mod_diff = (index_of_note - index_of_next_note).abs

    if mod_diff > $scale_ring.length / 2
      if index_of_note < index_of_next_note
        index_of_note += $scale_ring.length
      else
        index_of_next_note += $scale_ring.length
      end
    end
    $scale_ring[(((index_of_note + index_of_next_note) / 2).floor)]
  end

  # Given a note in the scale, return the note at an offset within the scale
  def get_note_at_offset(note, offset)
    $scale_ring[($scale_ring.index(note) + offset) % $scale_ring.length]
  end

  # Given two notes, find a good passing note between them
  def get_passing_note(note_1, note_2)
    # Are they adjacent notes in the scale?
    diff = $scale_ring.index(note_1) - $scale_ring.index(note_2)
    if (diff == 1 || diff == $scale_ring.length - 1)
      # If they are adjacent, choose either root note, one higher, or a two lower
      [note_1, note_2, get_note_at_offset(note_1, + 1), get_note_at_offset(note_1, - 2)]
    elsif (diff == -1 || diff == -($scale_ring.length - 1))
      # If they are adjacent, choose either root note, one lower, or a two higher
      [note_1, note_2, get_note_at_offset(note_1, - 1), get_note_at_offset(note_1, + 2)]
    else
      # If they are not adjacent, find the median
      [find_median_note(note_1, note_2)]
    end
  end

  ############## TRANSFORMATION FUNCTIONS ################

  # For each beat, unify with a suitable sub-melody by defining functions which unify notes and rhythms to it
  def transform_beat(beat, next_beat)
    fate = rand()
    if (fate < P_SINGLE)
      transform_beat_single(beat)
    elsif (fate < P_SINGLE + P_DOUBLE)
      transform_beat_double(beat, next_beat)
    elsif (fate < P_SINGLE + P_DOUBLE + P_TRIPLE)
      transform_beat_triple(beat, next_beat)
    elsif (fate < P_SINGLE + P_DOUBLE + P_TRIPLE + P_QUADRUPLE)
      transform_beat_quadruple(beat, next_beat)
    else
      transform_beat_quintuple(beat, next_beat)
    end
  end

  # Place a single note in the beat
  def transform_beat_single(beat)
    # There is only one note for this beat so it should be the root note
    $constraints << all(eq(beat[:rhythm], [1]), eq(beat[:notes], [beat[:root_note]]))
  end

  def transform_beat_double(beat, next_beat)
    # Split the beat in half
    $constraints << eq(beat[:rhythm], [0.5, 0.5])

    if (next_beat == nil)
      # This is the last note of the piece
      $constraints << eq(beat[:notes], [beat[:root_note], beat[:root_note]]) # TODO: fix this so that it does something more interesting!
    else
      # The first note must be the root of this beat
      # The second note should lead into the next note
      options_for_second_note = get_passing_note(beat[:root_note], next_beat[:root_note])

      options_for_both_notes = []
      for i in 0..options_for_second_note.length - 1
        options_for_both_notes << eq(beat[:notes], [beat[:root_note], options_for_second_note[i]])
      end
      $constraints << conde(*options_for_both_notes)
    end
  end

  def transform_beat_triple(beat, next_beat)
    # Split the beat into three, 3 cases
    cases = [[eq(beat[:rhythm], [0.25, 0.25, 0.5])],
    [eq(beat[:rhythm], [0.5, 0.25, 0.25])],
    [eq(beat[:rhythm], [Rational(1, 3), Rational(1, 3), Rational(1, 3)])]]

    # CASE 1: The first and third note must be the root of this beat and the middle one an adjacent note
    cases[0] << conde(
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], 1), beat[:root_note]]),
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], - 1), beat[:root_note]]))

    # CASE 2 and 3: The first must be the root of this beat and either:
    options = []
    # Only valid if this is not the last note of the piece
    if !next_beat == []
      ## second also the root note and third a passing note TODO: (not the same one as the root)
      options << eq(beat[:notes], [beat[:root_note], beat[:root_note], get_passing_note(beat[:root_note], next_beat[:root_note])])
    end

    ## third is root note and the second is an adjacent one
    options << conde(
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], 1), beat[:root_note]]),
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], - 1), beat[:root_note]]))

    ## TODO: neither second or third are root notes but 'walk' to the next note

    cases[1] << conde(*options)
    cases[2] << conde(*options)

    cases.map! do
      |x| all(*x)
    end
    $constraints << conde(*cases)
  end

  def transform_beat_quadruple(beat, next_beat)
    # Split the note into 4
    $constraints << eq(beat[:rhythm], [0.25, 0.25, 0.25, 0.25])

    # The first note must be the root
    options = []
    # One other must be the root
    ## Second TODO: make the next ones 'walk'

    ## Third. Second must be adjacent and fourth is leading to the next. Only valid if not the final note of the melody.
    if next_beat != nil
      options << conde(
      eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], 1), beat[:root_note], get_passing_note(beat[:root_note], next_beat[:root_note]).choose]),
      eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], - 1), beat[:root_note], get_passing_note(beat[:root_note], next_beat[:root_note]).choose]))
    end

    ## Fourth. Second and third are each side, or on the same side (either one)
    options << conde(
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], 1), get_note_at_offset(beat[:root_note], 2), beat[:root_note]]),
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], - 1), get_note_at_offset(beat[:root_note], - 2), beat[:root_note]]),
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], 2), get_note_at_offset(beat[:root_note], 1), beat[:root_note]]),
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], - 2), get_note_at_offset(beat[:root_note], - 1), beat[:root_note]]),
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], + 1), get_note_at_offset(beat[:root_note], - 1), beat[:root_note]]),
    eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], - 1), get_note_at_offset(beat[:root_note], + 1), beat[:root_note]]))

    $constraints << conde(*options)
  end

  def transform_beat_quintuple(beat, next_beat)
    # Constrain the rhythm
    $constraints << eq(beat[:rhythm], [0.25, 0.25, 0.25, 0.125, 0.125])

    # One simple pattern for now TODO: actually do this properly
    $constraints << eq(beat[:notes], [beat[:root_note], get_note_at_offset(beat[:root_note], 1), get_note_at_offset(beat[:root_note], 2), get_note_at_offset(beat[:root_note], 1), beat[:root_note]])
  end

  #######################################################

  # Make the notes into fresh variables
  for i in 0..canon.length - 1
    for j in 0..canon[i].length - 1
      canon[i][j][:rhythm] = fresh
      canon[i][j][:notes] = fresh
    end
  end

  # Initialise the constraints
  $constraints = []

  # Transform all the beats
  for i in 0..canon.length - 1
    for j in 0..canon[i].length - 1
      next_beat = nil
      # is the next beat in this bar?
      if j == canon[i].length - 1
        # NO, is it in the next?
        if i == canon.length - 1
          # NO (there is no next beat)
          next_beat = nil
        else
          # YES (the next beat is the first beat of the next bar)
          next_beat = canon[i+1][0]
        end
      else
        # YES (the next beat is in this bar)
        next_beat = canon[i][j + 1]
      end
      transform_beat(canon[i][j], next_beat)
    end
  end

  # run the query using q, a fresh query variable
  q = fresh
  run(q, eq(q, canon), *$constraints)
end

len = canon_results.length
print canon_results[20]
puts " "
