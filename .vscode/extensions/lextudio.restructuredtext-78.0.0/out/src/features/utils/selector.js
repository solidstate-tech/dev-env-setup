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
const configuration_1 = require("./configuration");
const confPyFinder_1 = require("./confPyFinder");
/**
 *
 */
class RstTransformerSelector {
    static findConfDir(resource, channel) {
        return __awaiter(this, void 0, void 0, function* () {
            const rstPath = resource.fsPath;
            // Sanity check - the file we are previewing must exist
            if (!fs.existsSync(rstPath) || !fs.statSync(rstPath).isFile) {
                return Promise.reject('RST extension got invalid file name: ' + rstPath);
            }
            const configurations = [];
            const pathStrings = [];
            // A path may be configured in the settings. Include this path
            const confPathFromSettings = configuration_1.Configuration.loadSetting('confPath', null, resource);
            if (confPathFromSettings != null) {
                if (confPathFromSettings === '') {
                    const rst2html = new confPyFinder_1.RstTransformerConfig();
                    rst2html.label = '$(code) Use rst2html.py';
                    rst2html.description = 'Do not use Sphinx, but rst2html.py instead';
                    rst2html.confPyDirectory = '';
                    return rst2html;
                }
                const pth = path.join(path.normalize(confPathFromSettings), 'conf.py');
                const qpSettings = new confPyFinder_1.RstTransformerConfig();
                qpSettings.label = '$(gear) Sphinx: ' + pth;
                qpSettings.description += ' (from restructuredtext.confPath setting)';
                qpSettings.confPyDirectory = path.dirname(pth);
                return qpSettings;
            }
            // Add path to a directory containing conf.py if it is not already stored
            function addPaths(pathsToAdd) {
                pathsToAdd.forEach((confPath) => {
                    const pth = path.normalize(confPath);
                    if (pathStrings.indexOf(pth) === -1) {
                        const qp = new confPyFinder_1.RstTransformerConfig();
                        qp.label = '$(gear) Sphinx: ' + pth;
                        qp.confPyDirectory = path.dirname(pth);
                        configurations.push(qp);
                        pathStrings.push(pth);
                    }
                });
            }
            // Search for unique conf.py paths in the workspace and in parent
            // directories (useful when opening a single file, not a workspace)
            const paths1 = yield confPyFinder_1.findConfPyFiles(resource);
            const paths2 = confPyFinder_1.findConfPyFilesInParentDirs(rstPath);
            addPaths(paths1);
            addPaths(paths2);
            channel.appendLine('Found conf.py paths: ' + JSON.stringify(pathStrings));
            // The user can chose to use rst2hml.py instead of Sphinx
            const qpRstToHtml = new confPyFinder_1.RstTransformerConfig();
            qpRstToHtml.label = '$(code) Use rst2html.py';
            qpRstToHtml.description = 'Do not use Sphinx, but rst2html.py instead';
            qpRstToHtml.confPyDirectory = '';
            configurations.push(qpRstToHtml);
            if (configurations.length === 1) {
                return configurations[0];
            }
            // Found multiple conf.py files, let the user decide
            return vscode_1.window.showQuickPick(configurations, {
                placeHolder: 'Select how to generate html from rst files',
            });
        });
    }
}
exports.RstTransformerSelector = RstTransformerSelector;
//# sourceMappingURL=selector.js.map