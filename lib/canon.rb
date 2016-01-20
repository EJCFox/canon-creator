require "mini_kanren"

# This contains a fully fleshed-out canon, with a link to the matadata that created it
class Canon
  def initialize(metadata)
    @metadata = metadata.clone() # We don't want the original version to change when we fiddle arond with it here.
    @concrete_scale = nil
    @canon_skeleton = nil
    @canon_complete = nil
  end

  def get_concrete_scale()
    return @concrete_scale
  end

  def get_chord_prog()
    return @metadata.get_chord_progression
  end

  def get_canon_skeleton()
    return @canon_skeleton
  end

  def generate_concrete_scale()
    # Find the highest tonic lower than the lower limit
    min_tonic = SonicPi::Note.resolve_midi_note_without_octave(@metadata.get_key_note)
    lowest_note = SonicPi::Note.resolve_midi_note(@metadata.get_lowest_note)
    while lowest_note < min_tonic
      min_tonic -= 12
    end

    # Find the lowest tonic higher than the upper limit
    max_tonic = SonicPi::Note.resolve_midi_note(@metadata.get_key_note)
    highest_note = SonicPi::Note.resolve_midi_note(@metadata.get_highest_note)
    while highest_note > max_tonic
      max_tonic += 12
    end

    # ASSERT: the whole range is encompassed between the two tonics- min and max

    # Get the scale between those tonics
    num_octaves = (max_tonic - min_tonic) / 12
    concrete_scale = SonicPi::Scale.new(min_tonic, @metadata.get_key_type, num_octaves = num_octaves).notes

    # Convert to an array and trim to range
    concrete_scale = concrete_scale.to_a
    concrete_scale.delete_if { |note| (lowest_note != nil && note < lowest_note) || (highest_note != nil && note > highest_note) }
    @concrete_scale = concrete_scale
    puts @concrete_scale
  end

  def generate_chord_progression()
    # If the chord progression is given, do nothing except check it for consistency, else generate it.
    if @metadata.get_chord_progression != nil
      # The length of the chord progression must be the same as the number of beats in the bar
      if @metadata.get_chord_progression.length != @metadata.get_beats_in_bar
        raise "The chord progression given is not consistent with the time signature; the number of chords must match the beats in the bar."
      end
    else
      # Create a new array with a chord for each beat
      chord_progression = Array.new(@metadata.get_beats_in_bar)
      # State which chords are available
      chord_choice = [:I, :IV, :V, :VI]
      # Choose each chord at random except the last two which are always IV-I or V-I (plagal or perfect cadence)
      for i in 0..chord_progression.length - 3
        chord_progression[i] = chord_choice.choose
      end
      chord_progression[chord_progression.length - 2] = [:IV, :V].choose
      chord_progression[chord_progression.length - 1] = :I
      @metadata.chord_progression(chord_progression)
      return chord_progression
    end
  end

  def generate_canon_skeleton()
    metadata = @metadata # TODO: get a less hacky fix for passing the variables around!!
    concrete_scale = @concrete_scale
    # Use MiniKanren to get compatible notes
    canon_structure_options = MiniKanren.exec do
      @metadata = metadata
      @concrete_scale = concrete_scale
      extend SonicPi::Lang::Core
      extend SonicPi::RuntimeMethods
      # Generate the structure with the root notes as fresh variables
      canon = Array.new(@metadata.get_beats_in_bar)
      for i in 0..canon.length - 1
        canon[i] = Array.new(@metadata.get_beats_in_bar)
        for j in 0..canon[i].length - 1
          canon[i][j] = {root_note: fresh, rhythm: nil, notes: nil}
        end
      end

      # Add constraints
      constraints = []

      ## Add constraint: final root note is the tonic
      ### Find all the tonics in the given range and add their disjunction as a constraint
      mod_tonic = SonicPi::Note.resolve_midi_note(metadata.get_key_note) % 12
      tonics_in_scale = @concrete_scale.select { |note| (note % 12) == mod_tonic }

      conde_options = []
      tonics_in_scale.map { |tonic| conde_options << eq(canon[@metadata.get_beats_in_bar - 1][@metadata.get_beats_in_bar - 1][:root_note], tonic) }

      constraints << conde(*conde_options)

      ## Add constraint on beats, going BACKWARDS from the last. They must be within max_jump in either direction.
      ### Find notes in that chord from the scale
      def notes_in_chord(name)
        mod_tonic = SonicPi::Note.resolve_midi_note(@metadata.get_key_note) % 12
        case name
        when :I
          ### Find mods of notes needed
          ### I is tonics, thirds and fifths
          if @metadata.get_key_type == :major
            mod_third = (mod_tonic + 4) % 12
          else
            mod_third = (mod_tonic + 3) % 12
          end
          mod_fifth = (mod_tonic + 7) % 12
          ### Find notes from scale
          notes_in_I = @concrete_scale.select do |note|
            mod_note = note % 12
            (mod_note == mod_tonic) || (mod_note == mod_third) || (mod_note == mod_fifth)
          end
          return notes_in_I
        when :IV
          ### Find mods of notes needed
          ### IV is fourths, sixths and tonics
          if @metadata.get_key_type == :major
            mod_sixth = (mod_tonic + 9) % 12
          else
            mod_sixth = (mod_tonic + 8) % 12
          end
          mod_fourth = (mod_tonic + 5) % 12
          ### Find notes from scale
          notes_in_IV = @concrete_scale.select do |note|
            mod_note = note % 12
            (mod_note == mod_fourth) || (mod_note == mod_sixth) || (mod_note == mod_tonic)
          end
          return notes_in_IV
        when :V
          ### Find mods of notes needed
          ### V is fifths, sevenths and seconds
          if @metadata.get_key_type == :major
            mod_second = (mod_tonic + 2) % 12
            mod_seventh = (mod_tonic + 11) % 12
          else
            mod_second = (mod_tonic + 1) % 12
            mod_seventh = (mod_tonic + 10) % 12
          end
          mod_fifth = (mod_tonic + 7) % 12
          ### Find notes from scale
          notes_in_V = @concrete_scale.select do |note|
            mod_note = note % 12
            (mod_note == mod_fifth) || (mod_note == mod_seventh) || (mod_note == mod_second)
          end
          return notes_in_V
        when :VI
          ### Find mods of notes needed
          ### VI is sixths, tonics and thirds
          if @metadata.get_key_type == :major
            mod_third = (mod_tonic + 4) % 12
            mod_sixth = (mod_tonic + 9) % 12
          else
            mod_third = (mod_tonic + 3) % 12
            mod_sixth = (mod_tonic + 8) % 12
          end
          ### Find notes from scale
          notes_in_VI = @concrete_scale.select do |note|
            mod_note = note % 12
            (mod_note == mod_sixth) || (mod_note == mod_tonic) || (mod_note == mod_third)
          end
          return notes_in_VI
        else
          raise "Error: unrecognised chord #{ name }"
        end
      end

      def constrain_to_key_and_distance(current_beat_var, next_beat_var, chord_name)

        max_jump = @metadata.get_max_jump
        #puts max_jump

        ### Get all notes in the right chord then keep only those not too far from the next beat
        possible_notes = notes_in_chord(chord_name)
        project(next_beat_var, lambda do |next_beat|
          refined_possibilities = possible_notes.select do |note|
            b = (note - next_beat).abs <= max_jump #&& (note - next_beat).abs != 0
            if b != true && b != false
              raise "BOOOOOM"
            else
              b
            end
          end
          ### Return a conde clause of all these options
          conde_options = []
          refined_possibilities.map do |note|
            conde_options << eq(current_beat_var, note)
          end
          return conde(*conde_options)
        end)
      end

      ### Set the constraint for each note
      (canon.length - 1).downto(0) do |bar|
        (canon[bar].length - 1).downto(0) do |beat|
          ### No constraint for the final beat
          if !(bar == canon.length - 1 && beat == canon[bar].length - 1)
            if beat < canon[bar].length - 1
              ### Next beat is in the same bar
              constraints << constrain_to_key_and_distance(canon[bar][beat][:root_note], canon[bar][beat + 1][:root_note], @metadata.get_chord_progression[beat])
            else
              ### Next beat is in the next bar
              constraints << constrain_to_key_and_distance(canon[bar][beat][:root_note], canon[bar + 1][0][:root_note], @metadata.get_chord_progression[beat])
            end
          end
        end
      end

      ## Successive bars do not have the same note for the same position in the chord
#      def is_different(*vars)
#        var1, var2, var3, var4 = *vars
#        if (var4 == nil)
#          ### Three args
#          project(var1,
#          lambda do |var1| project(var2,
#            lambda do |var2| project(var3,
#              lambda do |var3|
#                (var1 != var2 && var1 != var3 && var2 != var3) ? lambda { |x| x } : lambda { |x| nil }
#              end)
#            end)
#          end)
#        else
#          ### Four args
#          project(var1,
#          lambda do |var1| project(var2,
#            lambda do |var2| project(var3,
#              lambda do |var3| project(var4,
#                lambda do |var4|
#                  (var1 != var2 && var1 != var3 && var1 != var4 && var2 != var3 && var2 != var4 && var3 != var4) ? lambda { |x| x } : lambda { |x| nil }
#                end)
#              end)
#            end)
#          end)
#        end
#      end

      ### Set the notes to be different in every bar for each beat
#      if @metadata.get_beats_in_bar == 3
#        for j in 0..@metadata.get_beats_in_bar - 1
#          constraints << is_different(canon[0][j][:root_note], canon[1][j][:root_note], canon[2][j][:root_note])
#        end
#      else
#        for j in 0..@metadata.get_beats_in_bar - 1
#          constraints << is_different(canon[0][j][:root_note], canon[1][j][:root_note], canon[2][j][:root_note], canon[3][j][:root_note])
#        end
#      end

      # Run the query
      q = fresh
      run(1, q, eq(q, canon), *constraints)
    end

    # Choose one to be this structure
    @canon_skeleton = canon_structure_options.choose
  end

  def populate_canon(skeleton)
    raise "Not implemented yet."
  end
end
