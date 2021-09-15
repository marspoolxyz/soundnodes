# soundnodes

Welcome to your new soundnodes project and to the internet computer development community. By default, creating a new project adds this README and some template files to your project directory. You can edit these template files to customize your project and to include your own code to speed up the development cycle.

To get started, you might want to explore the project directory structure and the default configuration file. Working with this project in your development environment will not affect any production deployment or identity tokens.

To learn more before you start working with soundnodes, see the following documentation available online:

- [Quick Start](https://sdk.dfinity.org/docs/quickstart/quickstart-intro.html)
- [SDK Developer Tools](https://sdk.dfinity.org/docs/developers-guide/sdk-guide.html)
- [Motoko Programming Language Guide](https://sdk.dfinity.org/docs/language-guide/motoko.html)
- [Motoko Language Quick Reference](https://sdk.dfinity.org/docs/language-guide/language-manual.html)

If you want to start working on your project right away, you might want to try the following commands:

```bash
cd soundnodes/
dfx help
dfx config --help
```
dfx canister --network ic create soundnodes --with-cycles 5000000000000
dfx canister --network ic create soundnodes_assets --with-cycles 5000000000000

dfx build --network ic soundnodes
dfx build --network ic soundnodes_assets

dfx canister --network ic install soundnodes
dfx canister --network ic install soundnodes_assets

dfx canister --network ic id soundnodes_assets
dfx deploy --network ic soundnodes_assets


<option value="SoundNodes-Django Reinhardt - Minor Swing-mp3-onlyeum-onlyeum-1627152417956275017">SoundNodes-Django Reinhardt - Minor Swing-mp3-onlyeum-onlyeum-1627152417956275017</option>

