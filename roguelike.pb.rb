### Generated by rprotoc. DO NOT EDIT!
### <proto file: roguelike.proto>
# package roguelike;
# 
# message GameMessage {
#   repeated CellMessage cells = 1;
#   //repeated CreatureMessage creatures = 2;
#   optional CreatureMessage player = 2;
# }
# 
# message CellMessage {
#   required sint32 x = 1;
#   required sint32 y = 2;
#   required string symbol = 3;
# }
# 
# message CreatureMessage {
#   required sint32 x = 1;
#   required sint32 y = 2;
#   required string symbol = 3;
# }

require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/service'
require 'protobuf/message/extend'

module Roguelike
  class GameMessage < ::Protobuf::Message
    defined_in __FILE__
    repeated :CellMessage, :cells, 1
    optional :CreatureMessage, :player, 2
  end
  class CellMessage < ::Protobuf::Message
    defined_in __FILE__
    required :sint32, :x, 1
    required :sint32, :y, 2
    required :string, :symbol, 3
  end
  class CreatureMessage < ::Protobuf::Message
    defined_in __FILE__
    required :sint32, :x, 1
    required :sint32, :y, 2
    required :string, :symbol, 3
  end
end