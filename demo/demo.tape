# VHS tape — renders the test-is-truth demo to a GIF.
# Install VHS (https://github.com/charmbracelet/vhs):  brew install vhs
# Then from the repo root:  vhs demo/demo.tape   →   assets/demo.gif

Output assets/demo.gif

Set FontSize 20
Set Width 1100
Set Height 640
Set Padding 24
Set Theme "Catppuccin Mocha"
Set PlaybackSpeed 1.0

Hide
Type "clear" Enter
Show

Sleep 500ms
Type "bash demo/run-demo.sh" Sleep 600ms Enter

# run-demo.sh paces itself; give it room to finish, then hold the last frame.
Sleep 26s
