import SwiftUI
import UIKit

/// Le champ de saisie des dictées.
///
/// `TextEditor` aurait suffi à afficher du texte, mais il ne dit pas où se
/// trouve le point d'insertion — et sans cette information, la rangée
/// d'accents ne pouvait qu'**ajouter à la fin**. Corriger « etait » en
/// « était » demandait alors d'effacer la moitié du mot. Or taper un accent au
/// bon endroit est précisément le geste que l'application veut rendre facile.
///
/// L'enveloppe autour de `UITextView` sert aussi à couper la ponctuation
/// intelligente d'iOS : elle remplace l'apostrophe droite par une courbe et les
/// guillemets par des chevrons typographiques. Le moteur d'orthographe
/// normalise déjà ces caractères, mais l'apprenant doit voir à l'écran
/// exactement ce qu'il a tapé, sans qu'une correction invisible s'interpose.
struct OrthoTextEditor: UIViewRepresentable {
    @Binding var text: String
    /// Le point d'insertion, exprimé en unités UTF-16 comme le veut UIKit.
    @Binding var selection: NSRange
    @Binding var isEditing: Bool

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textColor = .white
        view.tintColor = UIColor(Theme.bleuFrance)
        // Le même serif que `Theme.Typography.orthoSmall`. On passe par le
        // descripteur : le nom PostScript de New York n'est pas garanti, alors
        // que la variante `.serif` de la police système l'est.
        let base = UIFont.systemFont(ofSize: 19, weight: .semibold)
        view.font = base.fontDescriptor.withDesign(.serif)
            .map { UIFont(descriptor: $0, size: 19) } ?? base
        view.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.spellCheckingType = .no
        view.smartQuotesType = .no
        view.smartDashesType = .no
        view.smartInsertDeleteType = .no
        view.keyboardAppearance = .dark
        view.isScrollEnabled = true
        view.alwaysBounceVertical = false
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        // Ne réécrire que si la valeur diffère : réaffecter `text` à chaque
        // passage remettrait le curseur à la fin après chaque frappe.
        if view.text != text {
            view.text = text
        }
        let bounded = clamp(selection, to: view.text as NSString)
        if view.selectedRange != bounded {
            view.selectedRange = bounded
        }
        if isEditing && !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if !isEditing && view.isFirstResponder {
            view.resignFirstResponder()
        }
    }

    private func clamp(_ range: NSRange, to string: NSString) -> NSRange {
        let location = max(0, min(range.location, string.length))
        let length = max(0, min(range.length, string.length - location))
        return NSRange(location: location, length: length)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: OrthoTextEditor

        init(_ parent: OrthoTextEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.selection = textView.selectedRange
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Sans cette garde, déplacer le curseur pendant que SwiftUI
            // recompose relancerait une mise à jour en boucle.
            guard parent.selection != textView.selectedRange else { return }
            parent.selection = textView.selectedRange
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            guard !parent.isEditing else { return }
            parent.isEditing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            guard parent.isEditing else { return }
            parent.isEditing = false
        }
    }
}

extension String {
    /// Insère `piece` au point d'insertion et rend la nouvelle position du
    /// curseur — juste après ce qui vient d'être écrit.
    ///
    /// Une sélection non vide est remplacée : c'est le comportement d'un
    /// clavier, et le seul qui ne surprenne personne.
    func inserting(_ piece: String, at range: NSRange) -> (text: String, caret: NSRange) {
        let source = self as NSString
        let location = max(0, min(range.location, source.length))
        let length = max(0, min(range.length, source.length - location))
        let replaced = source.replacingCharacters(in: NSRange(location: location, length: length),
                                                  with: piece)
        let caret = NSRange(location: location + (piece as NSString).length, length: 0)
        return (replaced, caret)
    }
}

/// La même idée, sur une ligne : le champ des exercices d'orthographe.
///
/// Un exercice à saisie libre porte sur **un mot**. C'est justement là que
/// l'accent doit pouvoir s'insérer au milieu — corriger « eleve » demande
/// d'écrire un accent en position 1 puis en position 3. `TextField` ne dit pas
/// où est le curseur ; `UITextField`, si.
struct OrthoTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange
    @Binding var isEditing: Bool
    var placeholder: String = ""
    var tint: Color = Theme.bleuFrance
    var onSubmit: () -> Void = {}

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.backgroundColor = .clear
        field.textColor = .white
        field.tintColor = UIColor(tint)
        let base = UIFont.systemFont(ofSize: 26, weight: .bold)
        field.font = base.fontDescriptor.withDesign(.serif)
            .map { UIFont(descriptor: $0, size: 26) } ?? base
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.smartInsertDeleteType = .no
        field.keyboardAppearance = .dark
        field.returnKeyType = .done
        field.addTarget(context.coordinator,
                        action: #selector(Coordinator.editingChanged(_:)),
                        for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        if field.text != text { field.text = text }
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.3)])

        let length = (field.text as NSString? ?? "").length
        let location = max(0, min(selection.location, length))
        if let position = field.position(from: field.beginningOfDocument, offset: location),
           let range = field.textRange(from: position, to: position),
           field.selectedTextRange != range,
           selection.length == 0 {
            field.selectedTextRange = range
        }

        if isEditing && !field.isFirstResponder {
            field.becomeFirstResponder()
        } else if !isEditing && field.isFirstResponder {
            field.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        private let parent: OrthoTextField

        init(_ parent: OrthoTextField) { self.parent = parent }

        @objc func editingChanged(_ field: UITextField) {
            parent.text = field.text ?? ""
            parent.selection = caret(of: field)
        }

        func textFieldDidChangeSelection(_ field: UITextField) {
            let range = caret(of: field)
            guard parent.selection != range else { return }
            parent.selection = range
        }

        func textFieldDidBeginEditing(_ field: UITextField) {
            guard !parent.isEditing else { return }
            parent.isEditing = true
        }

        func textFieldDidEndEditing(_ field: UITextField) {
            guard parent.isEditing else { return }
            parent.isEditing = false
        }

        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            parent.onSubmit()
            return true
        }

        /// La position du curseur, ramenée en unités UTF-16.
        private func caret(of field: UITextField) -> NSRange {
            guard let selected = field.selectedTextRange else {
                return NSRange(location: (field.text as NSString? ?? "").length, length: 0)
            }
            let location = field.offset(from: field.beginningOfDocument, to: selected.start)
            let length = field.offset(from: selected.start, to: selected.end)
            return NSRange(location: max(0, location), length: max(0, length))
        }
    }
}
