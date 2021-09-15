dfx canister call soundnodes createUserProfile '("waheed")'
dfx canister call soundnodes createUserProfile '("gladguy")'
dfx canister call soundnodes getProfiles
dfx canister call soundnodes getSongs

dfx canister call soundnodes createSong
'( record {userId="gladguy";name="Elon Musk";createdAt=1626688419;caption="ElonMusk";tags=vec {"elon musk"};chunkCount=10;})'
