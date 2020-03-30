const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
  entry: "./src/index.imba",
  output: {
    path: __dirname + "/dist",
    filename: "[name].js",
  },
  resolve: {
    extensions: [".imba", ".js", ".json", ".css"],
  },
  module: {
    rules: [
      {
        test: /\.imba$/,
        loader: "imba/loader",
      },
      {
        test: /\.css$/,
        loader: "style-loader",
      },
      {
        test: /\.css$/,
        loader: "css-loader",
        options: {
          modules: {
            mode: "local",
            localIdentName: "[path][name]__[local]--[hash:base64:5]",
            context: path.resolve(__dirname, "src"),
            hashPrefix: "my-custom-hash",
          },
        },
      },
    ],
  },
  plugins: [new HtmlWebpackPlugin()],
};
