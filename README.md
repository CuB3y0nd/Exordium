# Exordium

A tiny linux kernel built from scratch.

## Setting up the Development Environment

Since we use the `GNU Assembler (GAS)` as assembler and `qemu` for emulation, you should ensure `binutils` and `qemu` are installed in your system. Also, `gcc` is necessary too.

## Compile Kernel

```bash
git clone https://github.com/CuB3y0nd/Exordium.git && cd Exordium
chmod +x ./start.sh
make clean && make
```

After `make`, you can find `exordium.img` generated in root directory of the project if no problems.

Use `./start.sh` to start emulate.

## License

[MIT](https://github.com/CuB3y0nd/Exordium/blob/master/LICENSE) © [CuB3y0nd](https://assembly.rip/).
