import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Trie "mo:base/Trie";
import Types "./Types";
import TrieMap "mo:base/TrieMap";

actor {

    public type Id = Nat32;
    private stable var next : Id = 0;

    // the data structure to store the songs.
    //private stable var Songs : Trie.Trie<Id, Song> = Trie.empty();  

    public type ChunkId = Types.ChunkId;
    public type ChunkData = Types.ChunkData;
    public type VideoId = Types.VideoId; // chosen by createVideo

    private stable var chunks : Trie.Trie<Types.ChunkId, ChunkData> = Trie.empty();       

    /// all chunks.
    private stable var Songs : Trie.Trie<Id, Song> = Trie.empty();       
    private stable var MP3Songs : Trie.Trie<Id, MP3Song> = Trie.empty();       


     /// Songs.
    public type MP3Song = {
        id : Id;
        name: Text;
        chunkCount: Nat;
    };

     /// Songs.
    public type Song = {
        id : Id;
        userId : Types.UserId;
        createdAt : Types.Timestamp;
        uploadedAt : Types.Timestamp;
        caption: Text;
        listenCount: Nat;
        name: Text;
        chunkCount: Nat;
    };
  

    public func greet(name : Text) : async Text {
        return "Hello, " # name # "!";
    };

    public type Service = actor {
        putVideoChunk : (videoId : VideoId, chunkNum : Nat, chunkData : ChunkData) -> async ?();
        getVideoChunk : query (videoId : VideoId, chunkNum : Nat) -> async ?ChunkData;
    }


};
