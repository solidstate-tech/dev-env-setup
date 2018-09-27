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
const path = require("path");
const vscode = require("vscode");
const util = require("./common");
const ExtensionDownloader_1 = require("./ExtensionDownloader");
const rstDocumentContent_1 = require("./features/rstDocumentContent");
const rstLinter_1 = require("./features/rstLinter");
const underline_1 = require("./features/underline");
const configuration_1 = require("./features/utils/configuration");
const statusBar_1 = require("./features/utils/statusBar");
const logger_1 = require("./logger");
const RstLanguageServer = require("./rstLsp/extension");
let _channel = null;
function activate(context) {
    return __awaiter(this, void 0, void 0, function* () {
        const extensionId = 'lextudio.restructuredtext';
        const extension = vscode.extensions.getExtension(extensionId);
        util.setExtensionPath(extension.extensionPath);
        _channel = vscode.window.createOutputChannel('reStructuredText');
        _channel.appendLine('Please visit https://www.restructuredtext.net to learn how to configure the extension.');
        _channel.appendLine('');
        _channel.appendLine('');
        const logger = new logger_1.Logger((text) => _channel.append(text));
        const disableLsp = configuration_1.Configuration.loadAnySetting('languageServer.disabled', true, null);
        // *
        if (!disableLsp) {
            yield configuration_1.Configuration.setRoot();
            yield ensureRuntimeDependencies(extension, logger);
        }
        // */
        // activate language services
        const rstLspPromise = RstLanguageServer.activate(context, _channel, disableLsp);
        // Status bar to show the active rst->html transformer configuration
        const status = new statusBar_1.default();
        // The reStructuredText preview provider
        const provider = new rstDocumentContent_1.default(context, _channel, status);
        const registration = vscode.workspace.registerTextDocumentContentProvider('restructuredtext', provider);
        // Hook up the provider to user commands
        const d1 = vscode.commands.registerCommand('restructuredtext.showPreview', showPreview);
        const d2 = vscode.commands.registerCommand('restructuredtext.showPreviewToSide', (uri) => __awaiter(this, void 0, void 0, function* () { return yield showPreview(uri, true); }));
        const d3 = vscode.commands.registerCommand('restructuredtext.showSource', showSource);
        context.subscriptions.push(d1, d2, d3, registration);
        context.subscriptions.push(vscode.commands.registerTextEditorCommand('restructuredtext.features.underline.underline', underline_1.underline), vscode.commands.registerTextEditorCommand('restructuredtext.features.underline.underlineReverse', (textEditor, edit) => underline_1.underline(textEditor, edit, true)));
        // Hook up the status bar to document change events
        context.subscriptions.push(vscode.commands.registerCommand('restructuredtext.resetRstTransformer', provider.resetRstTransformerConfig, provider));
        vscode.window.onDidChangeActiveTextEditor(status.update, status, context.subscriptions);
        status.update();
        const linter = new rstLinter_1.default();
        linter.activate(context.subscriptions);
        vscode.workspace.onDidOpenTextDocument((document) => __awaiter(this, void 0, void 0, function* () {
            if (isRstFile(document)) {
                yield provider.showStatus(document.uri, status);
            }
        }));
        vscode.workspace.onDidSaveTextDocument((document) => {
            if (isRstFile(document)) {
                provider.update(getPreviewUri(document.uri));
            }
        });
        const updateOnTextChanged = configuration_1.Configuration.loadSetting('updateOnTextChanged', 'true', null);
        if (updateOnTextChanged === 'true') {
            vscode.workspace.onDidChangeTextDocument((event) => {
                if (isRstFile(event.document)) {
                    provider.update(getPreviewUri(event.document.uri));
                }
            });
        }
        vscode.workspace.onDidChangeConfiguration(() => {
            vscode.workspace.textDocuments.forEach((document) => {
                if (document.uri.scheme === 'restructuredtext') {
                    // update all generated md documents
                    provider.update(document.uri);
                }
            });
        });
        return {
            initializationFinished: Promise.all([rstLspPromise])
                .then((promiseResult) => {
                // This promise resolver simply swallows the result of Promise.all.
                // When we decide we want to expose this level of detail
                // to other extensions then we will design that return type and implement it here.
            }),
        };
    });
}
exports.activate = activate;
function ensureRuntimeDependencies(extension, logger) {
    return util.installFileExists(util.InstallFileType.Lock)
        .then((exists) => {
        if (!exists) {
            const downloader = new ExtensionDownloader_1.ExtensionDownloader(_channel, logger, extension.packageJSON);
            return downloader.installRuntimeDependencies();
        }
        else {
            return true;
        }
    });
}
function isRstFile(document) {
    return document.languageId === 'restructuredtext'
        && document.uri.scheme !== 'restructuredtext'; // prevent processing of own documents
}
function showPreview(uri, sideBySide = false) {
    return __awaiter(this, void 0, void 0, function* () {
        let resource = uri;
        if (!(resource instanceof vscode.Uri)) {
            if (vscode.window.activeTextEditor) {
                // we are relaxed and don't check for markdown files
                resource = vscode.window.activeTextEditor.document.uri;
            }
        }
        if (!(resource instanceof vscode.Uri)) {
            if (!vscode.window.activeTextEditor) {
                // this is most likely toggling the preview
                return yield vscode.commands.executeCommand('restructuredtext.showSource');
            }
            // nothing found that could be shown or toggled
            return;
        }
        const preview = getPreviewUri(resource);
        return yield vscode.commands.executeCommand('vscode.previewHtml', preview, getViewColumn(sideBySide), `Preview '${path.basename(preview.fsPath)}'`);
    });
}
function getPreviewUri(uri) {
    return uri.with({ scheme: 'restructuredtext', path: uri.path, query: uri.toString() });
}
function getViewColumn(sideBySide) {
    const active = vscode.window.activeTextEditor;
    if (!active) {
        return vscode.ViewColumn.One;
    }
    if (!sideBySide) {
        return active.viewColumn;
    }
    switch (active.viewColumn) {
        case vscode.ViewColumn.One:
            return vscode.ViewColumn.Two;
        case vscode.ViewColumn.Two:
            return vscode.ViewColumn.Three;
    }
    return active.viewColumn;
}
function showSource(mdUri) {
    return __awaiter(this, void 0, void 0, function* () {
        if (!mdUri) {
            return yield vscode.commands.executeCommand('workbench.action.navigateBack');
        }
        const docUri = vscode.Uri.parse(mdUri.query);
        for (const editor of vscode.window.visibleTextEditors) {
            if (editor.document.uri.toString() === docUri.toString()) {
                return yield vscode.window.showTextDocument(editor.document, editor.viewColumn);
            }
        }
        const doc = yield vscode.workspace.openTextDocument(docUri);
        return yield vscode.window.showTextDocument(doc);
    });
}
// this method is called when your extension is deactivated
// tslint:disable-next-line:no-empty
function deactivate() {
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map