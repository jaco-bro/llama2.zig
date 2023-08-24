const Self = @This();
const std = @import("std");
const Attention = @import("attention.zig");
const Checkpoint = @import("checkpoint.zig");
const FeedForward = @import("feed_forward.zig");
const lib = @import("lib.zig");

allocator: std.mem.Allocator,
checkpoint: *const Checkpoint,
hidden_state: []f32,
logits: []f32,
attention: Attention,
feed_forward: FeedForward,

pub fn init(allocator: std.mem.Allocator, checkpoint: *const Checkpoint, seq_len: usize) !Self {
    return Self{
        .allocator = allocator,
        .checkpoint = checkpoint,
        .hidden_state = try allocator.alloc(f32, checkpoint.dim),
        .logits = try allocator.alloc(f32, checkpoint.vocab_size),
        .attention = try Attention.init(allocator, checkpoint, seq_len),
        .feed_forward = try FeedForward.init(allocator, checkpoint),
    };
}

pub fn deinit(self: *const Self) void {
    self.allocator.free(self.hidden_state);
    self.allocator.free(self.logits);
    self.attention.deinit();
    self.feed_forward.deinit();
}

pub fn forward(self: *const Self, token: usize, pos: usize) !void {
    const checkpoint = self.checkpoint;
    const dim = checkpoint.dim;
    const weights = checkpoint.weights;

    @memcpy(
        self.hidden_state,
        weights.token_embedding[(token * dim)..][0..self.hidden_state.len],
    );

    for (0..checkpoint.n_layers) |layer| {
        lib.rmsnorm(
            self.attention.input_buffer,
            self.hidden_state,
            weights.attention_input_rms[(layer * dim)..][0..dim],
        );

        try self.attention.forward(pos, layer);

        lib.add(self.hidden_state, self.attention.output_buffer);

        lib.rmsnorm(
            self.feed_forward.input_buffer,
            self.hidden_state,
            weights.ffn_input_rms[(layer * dim)..][0..dim],
        );

        try self.feed_forward.forward(layer);

        lib.add(self.hidden_state, self.feed_forward.output_buffer);
    }

    lib.rmsnorm(self.hidden_state, self.hidden_state, weights.final_rms);
    lib.matmul(self.logits, self.hidden_state, weights.classifier);
}
