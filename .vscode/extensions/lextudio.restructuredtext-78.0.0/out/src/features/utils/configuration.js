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
const vscode_1 = require("vscode");
class Configuration {
    static loadAnySetting(configSection, defaultValue, resource, header = 'restructuredtext') {
        return vscode_1.workspace.getConfiguration(header, resource).get(configSection, defaultValue);
    }
    static saveAnySetting(configSection, value, resource, header = 'restructuredtext') {
        return __awaiter(this, void 0, void 0, function* () {
            yield vscode_1.workspace.getConfiguration(header, resource).update(configSection, value);
            return value;
        });
    }
    static loadSetting(configSection, defaultValue, resource, header = 'restructuredtext', expand = true) {
        const result = this.loadAnySetting(configSection, defaultValue, resource, header);
        if (expand && result != null) {
            return this.expandMacro(result, resource);
        }
        return result;
    }
    static saveSetting(configSection, value, resource, header = 'restructuredtext') {
        return __awaiter(this, void 0, void 0, function* () {
            return yield this.saveAnySetting(configSection, value, resource, header);
        });
    }
    static setRoot(resource = null) {
        return __awaiter(this, void 0, void 0, function* () {
            const old = this.loadSetting('workspaceRoot', null, resource);
            if (old.indexOf('${workspaceRoot}') > -1) {
                yield this.saveSetting('workspaceRoot', this.expandMacro(old, resource), resource);
            }
        });
    }
    static expandMacro(input, resource) {
        if (resource == null) {
            return input;
        }
        let path;
        if (!vscode_1.workspace.workspaceFolders) {
            path = vscode_1.workspace.rootPath;
        }
        else {
            let root;
            if (vscode_1.workspace.workspaceFolders.length === 1) {
                root = vscode_1.workspace.workspaceFolders[0];
            }
            else {
                root = vscode_1.workspace.getWorkspaceFolder(resource);
            }
            path = root.uri.fsPath;
        }
        return input
            .replace('${workspaceRoot}', path)
            .replace('${workspaceFolder}', path);
    }
}
exports.Configuration = Configuration;
//# sourceMappingURL=configuration.js.map