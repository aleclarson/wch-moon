# wch-moon v0.0.1 

Compile `.moon` files with [wch v0.8+](https://github.com/aleclarson/wch)

### Caveat

Your package must have a `package.json` file with the following structure:

```json
{
  "main": "foo/init.lua",
  "devDependencies": {
    "wch-moon": "^0.0.1"
  }
}
```

Obviously, it would be great if `wch-moon` worked with rockspecs.

