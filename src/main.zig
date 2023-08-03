const std = @import("std");

const checkpoint = @import("checkpoint.zig");
const tokenizer = @import("tokenizer.zig");
const transformer = @import("transformer.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    defer arena.deinit();

    const allocator = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    var config: checkpoint.Config = undefined;
    var weights: checkpoint.Weights = undefined;

    try checkpoint.readFile(allocator, "stories15M.bin", &config, &weights);
    try stdout.print("{}\n", .{config});

    var vocab: [][]u8 = try allocator.alloc([]u8, config.vocab_size);
    var word_scores: []f32 = try allocator.alloc(f32, config.vocab_size);

    const max_word_length = try tokenizer.readFile(allocator, "tokenizer.bin", vocab, word_scores);
    _ = max_word_length; // TODO

    var run_state: transformer.RunState = undefined;

    try transformer.allocRunState(allocator, config, &run_state);
}
