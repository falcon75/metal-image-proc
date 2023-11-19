# 

## Install Deps (macOS)
```bash
brew install opencv
```
### Build and Run
```bash
make all
./build/blur_basic
```

### Input and Output

![input](media/input.jpg)
![output](media/basic.jpg)

### Analyse
```bash
xctrace record --launch -- ./build/blur_basic
# open resulting .trace file in instruments
```

![Trace](media/trace.png)