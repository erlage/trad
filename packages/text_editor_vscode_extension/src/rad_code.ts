// Copyright (c) 2022-2023, H. Singh <hamsbrar@gmail.com>. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import * as vscode from 'vscode';
import { config } from './config';
import { Parser } from './parser/parser';
import { VisualJSX } from './visual-jsx/visual-jsx';

export class RadCode {
    private runTimeout: NodeJS.Timer | undefined = undefined;

    constructor(context: vscode.ExtensionContext) {
        let activeEditor = vscode.window.activeTextEditor;

        context.subscriptions.push(vscode.commands.registerCommand('rad.jsxToggle', () => {
            config.setJsxEnable(!config.jsxEnable);
            this.triggerRun();
        }));

        context.subscriptions.push(vscode.commands.registerCommand('rad.jsxTogglePrettyMode', () => {
            config.setJsxEnablePrettyMode(!config.jsxEnablePrettyMode);
            this.triggerRun();
        }));

        context.subscriptions.push(vscode.commands.registerCommand('rad.jsxToggleExperimentParsingOfficialSyntax', () => {
            config.setJsxEnableExperimentParsingOfficialSyntax(!config.jsxEnableExperimentParsingOfficialSyntax);
            this.triggerRun();
        }));

        vscode.workspace.onDidChangeConfiguration((_) => {
            config.refresh();
            this.triggerRun();
        });

        vscode.window.onDidChangeActiveTextEditor(editor => {
            if (editor) {
                this.triggerRun();
            }
        }, null, context.subscriptions);

        vscode.workspace.onDidChangeTextDocument(event => {
            if (activeEditor && event.document === activeEditor.document) {
                this.triggerRun(true);
            }
        }, null, context.subscriptions);
    }

    public run(): void {
        this.triggerRun(true);
    }

    private triggerRun(throttle = false): void {
        if (this.runTimeout) {
            clearTimeout(this.runTimeout);
            this.runTimeout = undefined;
        }
        if (throttle) {
            this.runTimeout = setTimeout(this.dispatchRun, 100);
        } else {
            this.dispatchRun();
        }
    }

    private dispatchRun() {
        let activeEditor = vscode.window.activeTextEditor;
        if (!activeEditor) {
            return;
        }

        if (activeEditor.document.languageId.toLowerCase() !== 'dart') {
            return;
        }

        const documentText = activeEditor.document.getText();
        const parser = new Parser(documentText);

        const visualJSX = new VisualJSX(parser, activeEditor);
        visualJSX.run();
    }
}