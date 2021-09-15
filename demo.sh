dfx canister call soundnodes createUserProfile '("waheed")'
dfx canister call soundnodes createUserProfile '("gladguy")'
dfx canister call soundnodes getProfiles
dfx canister call soundnodes getSongs
dfx canister call soundnodes getSongChunk '("test",1)'

dfx canister call soundnodes createSong
'( record {userId="gladguy";name="Elon Musk";createdAt=1626688419;caption="ElonMusk";tags=vec {"elon musk"};chunkCount=10;})'


dfx  canister call soundnodes mintNFT '( record {user="jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae";metadata=vec {0 1 2 3 4})'

dfx canister call soundnodes supply "(\"\")"
dfx canister call soundnodes metadata "(\"\")"

dfx canister call soundnodes balance "(record { user = (variant { \"principal\" = principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\" }); token = \"\" } )"
dfx canister --network ic install soundnodes --argument="(\"Toniq Token\", \"NIQ\", 6, 100_000_000_000_000:nat, principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\")"

dfx canister install soundnodes --all --mode reinstall --argument="(principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\")"
dfx canister --network ic install soundnodes --argument="(\"Toniq Token\", \"NIQ\", 6, 100_000_000_000_000:nat, principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\")"

dfx canister install soundnodes --mode reinstall --argument="(\"Toniq Token\", \"NIQ\", 6, 100_000_000_000_000:nat, principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\")"

dfx canister call soundnodes balance "(record { user = (variant { \"principal\" = principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\" }); token = \"\" } )"

dfx canister call soundnodes metadata "(\"\")"


ERC721
/home/waheed/dfx7/NFT/toniq-labs/soundnodes

dfx canister install soundnodes --mode reinstall --argument="(\"soundnodes NFT\", \"soundnodes\", 100_000_000_000_000:nat, principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\")"
dfx canister install soundnodes --mode reinstall --argument="(principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\")"

dfx canister call soundnodes mintNFT "(record { to = (variant { \"principal\" = principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\" });} )"
dfx canister call soundnodes mintNFT "(record { to = (variant { \"principal\" = principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\" }); metadata = "\CA\FF\FE"} )"

dfx canister call soundnodes balance "(record { to = (variant { \"principal\" = principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\" }); } )"
dfx canister call soundnodes balance "(record { user = (variant { address = \"97c5811f179af86bcb47b32b535d4059b02072e76ddcef91a66025439f708e68\" }); token = \"\" } )"
dfx canister call soundnodes balance "(record { user = (variant { \"principal\" = principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\" }); token = \"\" } )"

dfx canister call soundnodes metadata "(\"\")"
dfx canister call soundnodes getRegistry

dfx canister install soundnodes --mode reinstall --argument="(principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\")"

dfx canister call soundnodes getIndex '("xr5tq-eyaaa-aaaah-qacbq-caiba-eaqaa-abaaa-q")'
dfx canister call soundnodes getIndex '("e2qff-kqkor-uwiaa-aaaaa-b4aaq-maqcm-rshe")'
dfx deploy soundnodes  --argument="(principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\")"


dfx canister --network ic create soundnodes --with-cycles 2000000000000
dfx build --network ic soundnodes
dfx canister --network ic install soundnodes --argument="(principal \"jjugn-qkdh2-qdmjy-y4msd-juatg-qr63r-7gy72-7rfn6-ykwhg-ygt44-7ae\")"
dfx canister --network ic id soundnodes
df5og-6qaaa-aaaah-qafoq-cai
dfx canister --network ic call soundnodes getIndex '("lr7va-pykor-uwiaa-aaaaa-b4aaq-maqca-aaau7-q")'

dfx canister --network ic create soundnodes_assets --with-cycles 2000000000000
gxezl-oiaaa-aaaah-qafqa-cai
dfx build --network ic soundnodes_assets
dfx canister --network ic install soundnodes_assets --with-cycles 2000000000000
dfx canister --network ic id soundnodes_assets
df5og-6qaaa-aaaah-qafoq-cai

dfx canister --network ic call soundnodes_assets getIndex '("lr7va-pykor-uwiaa-aaaaa-b4aaq-maqca-aaau7-q")'


dfx wallet balance


Waheed : $100
ykpqe-azxjy-mrpj5-cjdet-u5y2w-gxj6t-wpoui-gsizj-fjtx5-y537t-lqe
dfx identity --network ic set-wallet --force k7tlp-fyaaa-aaaah-qaiqa-cai

dfx identity get-principal


dfx canister --network ic create soundnodes --with-cycles 2000000000000
dfx canister --network ic create soundnodes_assets --with-cycles 2000000000000


dfx build --network ic soundnodes_assets
dfx build --network ic soundnodes

dfx canister --network ic install soundnodes_assets 
dfx canister --network ic install soundnodes 

//Get canister ID
dfx canister --network ic id soundnodes
p7o7u-6qaaa-aaaah-qbniq-cai

//Get canister ID
dfx canister --network ic id soundnodes_assets
pypza-tiaaa-aaaah-qbnia-cai

  "soundnodes": {
    "ic": "f4spi-iqaaa-aaaah-qaf2q-cai"
  },
  "soundnodes_assets": {
    "ic": "fvreu-6yaaa-aaaah-qaf3a-cai"
  }
