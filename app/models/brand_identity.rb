class BrandIdentity
  NAME = "KnowShow"
  DEFAULT_CONCEPT_KEY = "drive"
  ICON_VERSION = 2
  DESCRIPTION = "Know your gigs. Own the show. Create your company and staff live music touring gigs in KnowShow. Crew, musicians and engineers can build free profiles and find work."
  Concept = Data.define(:key, :name, :character, :description, :colors)
  CONCEPTS = [
    Concept.new(key: "signal", name: "Signal", character: "Clean. Geometric. Confident.",
      description: "A compact, balanced wordmark. The most versatile direction for an app, a tour laminate or a crew shirt.", colors: [ "#3979ff", "#8fcaff" ]),
    Concept.new(key: "afterhours", name: "Afterhours", character: "Fast. Condensed. Electric.",
      description: "Forward-leaning type and a tighter footprint. The strongest sports-app influence, with an unmistakable late-night energy.", colors: [ "#3677ff", "#d0e6ff" ]),
    Concept.new(key: "backstage", name: "Backstage", character: "Quiet. Precise. Premium.",
      description: "A restrained, beautifully simple wordmark. More private members' club than scoreboard; polished without feeling corporate.", colors: [ "#568cff", "#a6baff" ]),
    Concept.new(key: "headliner", name: "Headliner", character: "Bold. Distinctive. Stage-ready.",
      description: "Two weights as well as two blues. A lighter know meets a heavier show for a memorable touring-first identity.", colors: [ "#74a9ff", "#3274ff" ]),
    Concept.new(key: "tempo", name: "Tempo", character: "Signal, with a little movement.",
      description: "Open geometric letters with a subtle forward lean. The cleanest of the hybrids, with a little more energy than Signal.", colors: [ "#3979ff", "#99caff" ]),
    Concept.new(key: "momentum", name: "Momentum", character: "The middle ground.",
      description: "Signal's geometric shape, a tighter footprint and a measured forward lean. A little more weight and energy, with clear letter shapes.", colors: [ "#3979ff", "#a7cfff" ]),
    Concept.new(key: "drive", name: "Drive", character: "More weight. More attitude.",
      description: "A heavier geometric wordmark with a narrower footprint and stronger lean. Closer to Afterhours, while keeping the letters open and easy to read.", colors: [ "#3979ff", "#bddcff" ])
  ].freeze

  def self.concept(key = nil)
    CONCEPTS.find { |concept| concept.key == key } || default_concept
  end

  def self.default_concept = CONCEPTS.find { |concept| concept.key == DEFAULT_CONCEPT_KEY }
  def self.icon_path(format = "svg") = "/brand/knowshow-#{DEFAULT_CONCEPT_KEY}-icon.#{format}?v=#{ICON_VERSION}"
  def self.social_image_path = "/brand/knowshow-#{DEFAULT_CONCEPT_KEY}-social.png"

  def self.refinements
    %w[tempo momentum drive].map { |key| concept(key) }
  end
end
