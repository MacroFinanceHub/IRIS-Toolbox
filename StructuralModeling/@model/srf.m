function [s, range, select] = srf(this, time, varargin)
% srf  Shock response functions, first-order solution only
%
% __Syntax__
%
%     S = srf(M, NPer, ...)
%     S = srf(M, Range, ...)
%
%
% __Input Arguments__
%
% * `M` [ model ] - Model object whose shock responses will be simulated.
%
% * `Range` [ numeric | char ] - Simulation date range with the first date
% being the shock date.
%
% * `NPer` [ numeric ] - Number of simulation periods.
%
%
% __Output Arguments__
%
% * `S` [ struct ] - Databank with shock response time series.
%
%
% __Options__
%
% * `'Delog='` [ *`true`* | `false` ] - Delogarithmise shock responses for
% log variables afterwards.
%
% * `'Select='` [ cellstr | *`@all`* ] - Run the shock response function
% for a selection of shocks only; `@all` means all shocks are simulated.
%
% * `'Size='` [ *`@auto`* | numeric ] - Size of the shocks that will be
% simulated; `@auto` means that each shock will be set to its std dev
% currently assigned in the model object `M`.
%
%
% __Description__
% 
%
% __Example__
%

% -IRIS Macroeconomic Modeling Toolbox.
% -Copyright (c) 2007-2017 IRIS Solutions Team.

TYPE = @int8;

opt = passvalopt('model.srf', varargin{:});

if ischar(opt.select)
    opt.select = regexp(opt.select, '\w+', 'match');
end

%--------------------------------------------------------------------------

ixe = this.Quantity.Type==TYPE(31) | this.Quantity.Type==TYPE(32); 
ne = sum(ixe);
nv = length(this);
lse = this.Quantity.Name(ixe);

% Select shocks.
if isequal(opt.select, @all)
    posOfSelected = 1 : ne;
else
    numOfSelected = length(opt.select);
    posOfSelected = nan(1, numOfSelected);
    for i = 1 : length(opt.select)
        x = find( strcmp(opt.select{i}, lse) );
        if length(x)==1
            posOfSelected(i) = x;
        end
    end
    assert( ...
        ~any(isnan(posOfSelected)), ...
        'model:srf', ...
        exception.Base('Model:InvalidName', 'error'), ...
        'shock', opt.select{isnan(posOfSelected)} ...
    );
end
select = lse(posOfSelected);
numOfSelected = length(select);

% Set size of shocks.
if strcmpi(opt.size, 'std') ...
        || isequal(opt.size, @auto) ...
        || isequal(opt.size, @std)
    sizeOfShocks = this.Variant.StdCorr(:, posOfSelected, :);
else
    sizeOfShocks = opt.size*ones(1, numOfSelected, nv);
end

func = @(T, R, K, Z, H, D, U, Omg, variantRequested, numOfPeriods) ...
    timedom.srf(T, R(:, posOfSelected), [ ], Z, H(:, posOfSelected), [ ], U, [ ], ...
    numOfPeriods, sizeOfShocks(1, :, variantRequested));

[s, range, select] = responseFunction(this, time, func, select, opt);
for i = 1 : length(select)
    s.(select{i}).data(1, i, :) = sizeOfShocks(1, i, :);
    s.(select{i}) = trim(s.(select{i}));
end

s = addparam(this, s);

end
