package ai.haoclaw.app.ui

import androidx.compose.runtime.Composable
import ai.haoclaw.app.MainViewModel
import ai.haoclaw.app.ui.chat.ChatSheetContent

@Composable
fun ChatSheet(viewModel: MainViewModel) {
  ChatSheetContent(viewModel = viewModel)
}
