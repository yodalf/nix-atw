with import <nixpkgs> {
  crossSystem = {
    config = "armv7l-unknown-linux-gnueabihf";
  };
};

mkShell {
  buildInputs = [ zlib ]; # your dependencies here
}
