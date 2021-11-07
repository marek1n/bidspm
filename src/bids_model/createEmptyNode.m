function node = createEmptyNode(level)
  %
  % (C) Copyright 2020 CPP_SPM developers

  node =  struct( ...
                 'Level', level, ...
                 'Transformations', {createEmptyTransformation()}, ...
                 'Model', createEmptyModel(), ...
                 'DummyContrasts', {{' '}});
end
