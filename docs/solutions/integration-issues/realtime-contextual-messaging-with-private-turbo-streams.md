---
problem_type: integration_feature
component:
  - contextual_messaging
  - turbo_stream_broadcasting
  - action_cable
  - view_component_rendering
symptoms:
  - recipients had to reload conversations to see new messages
  - shared broadcasts could not render viewer-relative message alignment safely
tags:
  - rails
  - hotwire
  - turbo-streams
  - action-cable
  - realtime
  - messaging
  - private-streams
---

# Realtime contextual messaging with private Turbo streams

## Problem

Persisting a contextual message did not update another participant's open conversation. A single conversation-wide stream was also the wrong presentation boundary: the same message must render as sent for one user and received for another.

## Root cause

The message workflow ended with an HTTP redirect and had no Action Cable subscription or broadcast. Message markup depends on the viewer, so broadcasting one shared pre-rendered fragment would produce incorrect alignment and broaden the subscription scope.

## Solution

Subscribe the conversation page to a signed composite stream for the conversation and current user:

```haml
= turbo_stream_from @conversation, current_user
```

Persist the message, memberships, read state, and notifications inside the transaction. Broadcast only after the transaction completes:

```ruby
message = ContextualMessage.transaction do
  conversation = Conversation.find_or_create_by!(context:)
  participants.each { |user| conversation.memberships.find_or_create_by!(user:) }
  message = conversation.messages.create!(sender:, body:)
  conversation.memberships.find_by!(user: sender).mark_as_read!
  notify_recipients(message)
  message
end

ConversationMessageBroadcaster.new(message:).call
message
```

The broadcaster renders once per membership, using that membership's user as the component viewer:

```ruby
message.conversation.memberships.includes(:user).find_each do |membership|
  html = ApplicationController.render(
    Usr::ConversationMessageComponent.new(message:, current_user: membership.user),
    layout: false
  )

  Turbo::StreamsChannel.broadcast_append_to(
    message.conversation,
    membership.user,
    target: ActionView::RecordIdentifier.dom_id(message.conversation, :messages),
    html:
  )
end
```

Return `204 No Content` for Turbo submissions. The sender receives the same private broadcast as every other participant, avoiding duplicate optimistic and server-rendered messages. Reset the form only after a successful submission.

Use a stable list target and stable message DOM IDs so Turbo can append predictably:

```haml
.d-flex.flex-column.gap-3{ id: dom_id(conversation, :messages) }

.d-flex{ id: dom_id(message), data: { message_id: message.id } }
```

## Security and operations

- Scope conversation lookup through the current user's memberships.
- Composite Turbo stream names are signed and include both conversation and viewer.
- The development async adapter supports the single Puma process; production Solid Cable delivers across application processes.
- Do not broadcast before commit, or subscribers can receive markup for data that later rolls back.

## Verification

Tests should cover persistence, participant authorization, one broadcast to each private stream, viewer-relative component rendering, safe body escaping, the Turbo `204` response, and the normal HTML redirect fallback.

Related notification lifecycle guidance: [read notification lifecycle](../logic-errors/read-notification-lifecycle-with-user-scoped-clearing-and-retention.md) and [notification preferences](../logic-errors/account-settings-with-notification-channel-and-topic-preferences.md).
