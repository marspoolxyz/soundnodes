import Demo "../../backend/Demo";
import Types "../../backend/Types";

module {
  public let allSongs : [Types.SongId] = [
    "alice-dog-0",
    "bob-fish-0",
    "cathy-bunny-0",
    "dexter-hampster-0",
    "esther-weasel-0",
  ];

  public let demoScript : [Demo.Command] = [
    #reset(#script 0), // clear CanCan state and set timeMode to #script.
    #createTestData{
      users  = ["alice", "bob",
                "cathy", "dex", "esther"];
      songs = [
        ("alice", "dog"),
        ("bob", "fish"),
        ("cathy", "bunny"),
        ("dexter", "hampster"),
        ("esther", "weasel"),
      ];
    },
    #putProfileFollow{
      userId = "alice";
      toFollow = "cathy";
      follows = true;
    },
    #putProfileFollow{
      userId = "cathy";
      toFollow = "alice";
      follows = true;
    },
    #assertSongFeed{
      userId = "alice";
      limit = ?1;
      songsPred =
        #equals(["cathy-bunny-0"]);
    },
    #assertSongFeed{
      userId = "cathy";
      limit = ?1;
      songsPred =
        #equals(["alice-dog-0"]);
    },
    #assertSongFeed{
      userId = "alice";
      limit = null;
      songsPred =
        #containsAll allSongs;
    },
    #assertSongFeed{
      userId = "bob";
      limit = null;
      songsPred =
        #containsAll allSongs;
    },
  ];
}
