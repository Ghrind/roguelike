# - Every item can be scaled to player level
# - Items can be found anywhere
# - Legendary items can be traded against the special currency
# - The special currency can also be used to get random high-quality items
# - User may spend special currency to fit an item to the player's level
#
# Items quality
#
# - Legendary: Item stats are fixed, has a fixed set of special property, may have a unique effect
# - White: Item stats are fixed, no special effect
#
# Items meta stats
#
# - Tier: Measure of how much the basic usage of this item is powerful (ie: a dagger versus a broad sword)
# - Level: Minimum level to use the item, variable stats of the item scale on this
# - Quality: How much special properies the item has and how they are distributed
module Roguelike
  class Item
    attr_reader :id

    def self.generate_id
      @_id = (@_id || -1).next
    end

    ATTRIBUTES = {
      worth: 1
    }

    attr_accessor *ATTRIBUTES.keys

    attr_accessor :cell

    def initialize(attributes = {})
      ATTRIBUTES.merge(attributes).each_pair do |k, v|
        send "#{k}=", v
      end
      @id = self.class.generate_id
    end

    def clone
      self.class.new cell: self.cell.clone, worth: self.worth # FIXME Code me better
    end
  end
end
