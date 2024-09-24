function block_choices = gen_choices(ntrial)
  % ntrial=36;
  choices = [ 1 2; 2 3; 1 3];
  block_choices = Shuffle(repmat(choices,ntrial/length(choices),1),2);
end
%! block_choices = gen_choices(36);
%! assert(all(size(block_choices) == [36     2]))
%! assert(all(size(unique(block_choices,'row')) == [3 2]
