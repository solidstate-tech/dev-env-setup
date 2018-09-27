'use strict';
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const fs = require("fs");
const path = require("path");
const vscode_1 = require("vscode");
/**
 * Configuration for how to transform rst files to html. Either use Sphinx
 * with a gven conf.py file, or use rst2html without any configuration
 */
class RstTransformerConfig {
    constructor() {
        this.description = 'Use Sphinx with the selected conf.py path';
    }
}
exports.RstTransformerConfig = RstTransformerConfig;
/**
 * Returns a list of conf.py files in the workspace
 */
function findConfPyFiles(resource) {
    return __awaiter(this, void 0, void 0, function* () {
        if (!vscode_1.workspace.workspaceFolders) {
            return [];
        }
        const items = yield vscode_1.workspace.findFiles(
        /*include*/ '{**/conf.py}', 
        /*exclude*/ '{}', 
        /*maxResults*/ 100);
        return urisToPaths(items, resource);
    });
}
exports.findConfPyFiles = findConfPyFiles;
function urisToPaths(uris, resource) {
    const paths = [];
    const workspaceFolder = vscode_1.workspace.getWorkspaceFolder(resource);
    uris.forEach((uri) => {
        if (uri.fsPath.startsWith(workspaceFolder.uri.fsPath)) {
            paths.push(uri.fsPath);
        }
    });
    return paths;
}
/**
 * Find conf.py files by looking at parent directories. Useful in case
 * a single rst file is opened without a workspace
 */
function findConfPyFilesInParentDirs(rstPath) {
    const paths = [];
    // Walk the directory up from the RST file directory looking for the conf.py file
    let dirName = rstPath;
    while (true) {
        // Get the name of the parent directory
        const parentDir = path.normalize(dirName + '/..');
        // Check if we are at the root directory already to avoid an infinte loop
        if (parentDir === dirName) {
            break;
        }
        // Sanity check - the parent directory must exist
        if (!fs.existsSync(parentDir) || !fs.statSync(parentDir).isDirectory) {
            break;
        }
        // Check this directory for conf.py
        const confPath = path.join(parentDir, 'conf.py');
        if (fs.existsSync(confPath) && fs.statSync(confPath).isFile) {
            paths.push(confPath);
        }
        dirName = parentDir;
    }
    return paths;
}
exports.findConfPyFilesInParentDirs = findConfPyFilesInParentDirs;
//# sourceMappingURL=confPyFinder.js.map