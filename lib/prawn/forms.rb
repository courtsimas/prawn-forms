# encoding: utf-8
#
# forms.rb : Interactive form support for prawn
#
# Copyright August 2009, James Healy. All Rights Reserved.
#
# This is free software. Please see the LICENSE file for details.

module Prawn
  module Forms

    def button(text)
      add_interactive_field(:Btn, :T => Prawn::Core::LiteralString.new(text),
                                  :DA => Prawn::Core::LiteralString.new("/Helv 0 Tf 0 g"),
                                  :F => 4,
                                  :Ff => 65536,
                                  :MK => {:CA => Prawn::Core::LiteralString.new(text), :BG => [0.75294, 0.75294, 0.75294], :BC => [0.75294, 0.75294, 0.75294]},
                                  :Rect => [304.5, 537.39, 429, 552.39])

    end

    def text_field(name, x, y, w, h, opts = {})
      x, y = map_to_absolute(x, y)

      field_dict = {:T => Prawn::Core::LiteralString.new(name),
                    :DA => Prawn::Core::LiteralString.new(
                      "/Helv #{font_size} Tf 0 g"),
                    :F => 4,
                    :Ff => flags_from_options(opts),
                    :BS => {:Type => :Border, :W => 1, :S => :S},
                    :MK => {:BC => [0, 0, 0]},
                    :Rect => [x, y, x + w, y + h]}

      if opts[:default]
        # Set the field's default text
        default = Prawn::Core::LiteralString.new(opts[:default])
        field_dict[:V] = field_dict[:DV] = default

        # Merge in the appearance stream fields, so the field shows the default
        # text when not selected. Per PDF32000_2008 12.7.1 (Interactive Forms:
        # General), the widget annotation for an appearance stream may be
        # merged into the field dictionary itself rather than appending it as a
        # child.
        field_dict.merge!(
          :Type => :Annot,
          :Subtype => :Widget,
          :AP => text_field_appearance_stream(opts[:default], w, h),
          :P => state.page.dictionary)
      end

      add_interactive_field(:Tx, field_dict)
    end

    private

    def add_interactive_field(type, opts = {})
      defaults = {:FT => type, :Type => :Annot, :Subtype => :Widget}
      annotation = ref!(opts.merge(defaults))
      acroform.data[:Fields] << annotation
      state.page.dictionary.data[:Annots] ||= []
      state.page.dictionary.data[:Annots] << annotation
    end

    # The AcroForm dictionary (PDF spec 8.6) for this document. It is
    # lazily initialized, so that documents that do not use interactive
    # forms do not incur the additional overhead.
    def acroform
      state.store.root.data[:AcroForm] ||= 
        ref!({:DR => acroform_resources, 
              :DA => Prawn::Core::LiteralString.new("/Helv 0 Tf 0 g"),
              :Fields => []})
    end

    # a resource dictionary for interactive forms. At a minimum,
    # must contain the font we want to use
    def acroform_resources
      helv = ref!(:Type     => :Font,
                  :Subtype  => :Type1,
                  :BaseFont => :Helvetica,
                  :Encoding => :WinAnsiEncoding)
      ref!(:Font => {:Helv => helv})
    end

    # Return a ref to a Form XObject containing the appearance stream for
    # a text field.
    #
    def text_field_appearance_stream(default_text, w, h)
      # Padding to make the appearance stream line up with the text box once
      # activated. Determined through experiment (Adobe Acrobat Pro 10.1.1,
      # OS X).
      pad_x, pad_y = -2, 7

      # Add the default text to the appearance stream. We lean on text_box to
      # provide wrapping, but we have to provide a custom callback to ensure
      # the font resources and stream are embedded in the form XObject, not
      # the page's content stream.
      #
      stream = "/Tx BMC q BT\n"
      font_refs = {}
      x, y = pad_x, bounds.height - h + pad_y
      text_box(default_text,
        :width => w - 4, # account for padding
        :height => h,
        :draw_text_callback => lambda { |text, options|
          new_x, new_y = options[:at]
          dx, dy = new_x - x, new_y - y
          x, y = new_x, new_y
          stream << "#{dx} #{dy} Td\n"

          font.encode_text(text).each do |subset, string|
            font_refs[font.identifier_for(subset)] = font.send(:register, subset)
            op = options[:kerning] && text.is_a?(Array) ? "TJ" : "Tj"
            stream << "/#{font.identifier_for(subset)} #{font_size} Tf\n" <<
              Prawn::Core::PdfObject(text, true) << " #{op}\n"
          end
        })
      stream << "ET Q EMC\n"

      normal = ref!(:Type => :XObject,
                    :Subtype => :Form,
                    :Matrix => [1.0, 0.0, 0.0, 1.0, 0.0, 0.0],
                    :FormType => 1,
                    :BBox => [0.0, 0.0, w, h],
                    :Length => stream.length,
                    :Resources => {
                      :ProcSet => [:PDF, :Text],
                      :Font => font_refs})
      normal << stream

      {:N => normal}
    end

    # Returns the integer value for the /Ff (flags) entry in the field
    # dictionary, based on the options provided.
    #
    def flags_from_options(opts)
      flags = 0

      flags |= 1<<12 if opts[:multiline]
      flags |= 1<<13 if opts[:password]

      if opts[:file_select]
        min_version 1.4
        flags |= 1<<20
      end

      if opts[:do_not_spell_check]
        min_version 1.4
        flags |= 1<<22
      end

      if opts[:do_not_scroll]
        min_version 1.4
        flags |= 1<<23
      end

      flags
    end
  end
end

require 'prawn/document'
Prawn::Document.send(:include, Prawn::Forms)
