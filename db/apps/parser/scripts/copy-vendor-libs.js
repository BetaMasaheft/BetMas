#!/usr/bin/env node
// Copies the browser-facing files of each package.json "dependencies" entry from
// node_modules into resources/{js,css,fonts}/external, where the pages built in
// modules/morphoparser.xqm load them from (see morpho:vendorLinks). Run via
// `npm run vendor:copy` (or `npm run vendor`, which installs first); the Ant
// "vendor" target does the same.
//
// resources/{js,css,fonts}/external are reproducible from package.json + this
// script, so they are gitignored; the xar must still contain them.

const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(__dirname, "..");
const NODE_MODULES = path.join(ROOT, "node_modules");
const DEST_ROOTS = {
	js: path.join(ROOT, "resources", "js", "external"),
	css: path.join(ROOT, "resources", "css", "external"),
	fonts: path.join(ROOT, "resources", "fonts", "external"),
};

// Each entry: [destination subfolder, [ [sourceRelativeToPackage, destFilename, root?, subdir?], ... ]]
// root picks the DEST_ROOTS entry (default "js"); subdir overrides the package's subfolder
// ("" = directly under the root).
const MANIFEST = {
	jquery: ["jquery", [["dist/jquery.min.js", "jquery.min.js"]]],
	bootstrap: [
		"bootstrap",
		[
			["dist/css/bootstrap.min.css", "bootstrap.min.css", "css"],
			["dist/js/bootstrap.min.js", "bootstrap.min.js"],
			// bootstrap.min.css reaches its glyphicon font via url(../fonts/...); the fonts go
			// to the flat fonts root and the url() is rewritten below.
			["dist/fonts/glyphicons-halflings-regular.eot", "glyphicons-halflings-regular.eot", "fonts", ""],
			["dist/fonts/glyphicons-halflings-regular.svg", "glyphicons-halflings-regular.svg", "fonts", ""],
			["dist/fonts/glyphicons-halflings-regular.ttf", "glyphicons-halflings-regular.ttf", "fonts", ""],
			["dist/fonts/glyphicons-halflings-regular.woff", "glyphicons-halflings-regular.woff", "fonts", ""],
			["dist/fonts/glyphicons-halflings-regular.woff2", "glyphicons-halflings-regular.woff2", "fonts", ""],
		],
	],
	"intro.js": [
		"intro.js",
		[
			["minified/intro.min.js", "intro.min.js"],
			["minified/introjs.min.css", "introjs.min.css", "css"],
		],
	],
};

let copied = 0;
for (const [pkg, [destSubdir, files]] of Object.entries(MANIFEST)) {
	const pkgDir = path.join(NODE_MODULES, pkg);
	if (!fs.existsSync(pkgDir)) {
		throw new Error(`${pkg} is listed in the vendor manifest but missing from node_modules - run npm install first`);
	}
	for (const [from, to, root = "js", subdir = destSubdir] of files) {
		const destDir = path.join(DEST_ROOTS[root], subdir);
		fs.mkdirSync(destDir, { recursive: true });
		const src = path.join(pkgDir, from);
		if (!fs.existsSync(src)) {
			throw new Error(`${pkg}: expected file ${from} not found at ${src}`);
		}
		fs.cpSync(src, path.join(destDir, to), { recursive: true });
		copied += 1;
	}
}

function rewriteFontUrls(cssSubdir, cssFilename, oldPrefix) {
	const cssPath = path.join(DEST_ROOTS.css, cssSubdir, cssFilename);
	const fontsRel = path.relative(path.dirname(cssPath), DEST_ROOTS.fonts).split(path.sep).join("/");
	const original = fs.readFileSync(cssPath, "utf8");
	const rewritten = original.split(oldPrefix).join(`${fontsRel}/`);
	if (rewritten === original) {
		throw new Error(
			`${cssPath}: expected to rewrite ${oldPrefix} references, but found none - did the package's CSS change?`,
		);
	}
	fs.writeFileSync(cssPath, rewritten);
}

rewriteFontUrls("bootstrap", "bootstrap.min.css", "../fonts/");

console.log(`Copied ${copied} vendor files/dirs into resources/{js,css,fonts}/external`);
