'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
/**
 * Status bar updates. Shows the selected RstTransformerConfig when a
 * restructuredtext document is active. If you click on the status bar
 * then the RstTransformerConfig is reset and you will need to select from
 * the menu when the preview is generated next time.
 */
class RstTransformerStatus {
    constructor() {
        this._selectedConfig = '';
        this._statusBarItem = vscode_1.window.createStatusBarItem(vscode_1.StatusBarAlignment.Left);
        this._statusBarItem.command = 'restructuredtext.resetRstTransformer';
        this._statusBarItem.tooltip = 'The active rst to html transformer (click to reset)';
    }
    setConfiguration(conf) {
        this._selectedConfig = conf;
        this.update();
    }
    update() {
        const editor = vscode_1.window.activeTextEditor;
        if (this._selectedConfig &&
            // editor is null for the preview window
            (editor == null || editor.document.languageId === 'restructuredtext')) {
            this._statusBarItem.text = this._selectedConfig;
            this._statusBarItem.show();
        }
        else {
            this._statusBarItem.hide();
        }
    }
}
exports.default = RstTransformerStatus;
//# sourceMappingURL=statusBar.js.map