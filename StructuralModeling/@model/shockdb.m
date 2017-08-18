function d = shockdb(varargin)
% shockdb  Create model-specific database with random shocks.
%
%
% __Syntax__
%
% Input arguments marked with a `~` sign may be omitted.
%
%     OutputData = shockdb(M, InputData, Range, ~NumberOfDraws,...)
%
%
% __Input arguments__
%
% * `M` [ model ] - Model object.
%
% * `InputData` [ struct | empty ] - Input database to which shock time
% series will be added; if omitted or empty, a new database will be
% created; if `D` already contains shock time series, the data generated by
% `shockdb` will be added up with the existing data.
%
% * `Range` [ numeric ] - Date range on which the shock time series will be
% generated and returned; if `D` already contains shock time series
% going before or after `Range`, these will be clipped down to `Range` in
% the output database.
%
% * `~NumberOfDraws` [ numeric ] - Number of draws (i.e. columns) generated
% for each shock; if omitted, the number of draws is equal to the number of
% alternative parameterizations in the model `M`, or to the number of
% columns in shock series existing in the input database, `InputData`.
%
%
% __Output arguments__
%
% * `OutputData` [ struct ] - Database with shock time series added.
%
%
% __Options__
%
% * `'ShockFunc='` [ `@lhsnorm` | `@randn` | *`@zeros`* ] - Function used to
% generate random draws for new shock time series; if `@zeros`, the new
% shocks will simply be filled with zeros; the random numbers will be
% adjusted by the respective covariance matrix implied by the current model
% parameterization.
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
TIME_SERIES_CONSTRUCTOR = getappdata(0, 'TIME_SERIES_CONSTRUCTOR');
TEMPLATE_SERIES = TIME_SERIES_CONSTRUCTOR( );

[this, d, range, nDraw, varargin] = ...
    irisinp.parser.parse('model.shockdb', varargin{:});
opt = passvalopt('model.shockdb', varargin{:});

%--------------------------------------------------------------------------

ixe = this.Quantity.Type==TYPE(31) | this.Quantity.Type==TYPE(32);
ne = sum(ixe);
nPer = length(range);
nAlt = length(this);
lsName = this.Quantity.Name(ixe);
lsLabel = getLabelOrName(this.Quantity);
lsLabel = lsLabel(ixe);

if isempty(d)
    E = zeros(ne, nPer);
else
    E = datarequest('e', this, d, range);
end
nShock = size(E, 3);

doChkSize( );

nLoop = max([nAlt, nShock, nDraw]);
if nShock==1 && nLoop>1
    E = repmat(E, 1, 1, nLoop);
end

strShockFunc = func2str(opt.shockfunc);
switch strShockFunc
    case 'lhsnorm'
        S = lhsnorm(sparse(1,ne*nPer), speye(ne*nPer), nLoop);
    otherwise
        S = opt.shockfunc(nLoop, ne*nPer);
end

for iLoop = 1 : nLoop
    if iLoop<=nAlt
        Omg = covfun.stdcorr2cov(this.Variant{iLoop}.StdCorr, ne);
        F = covfun.factorise(Omg);
    end
    iS = S(iLoop,:);
    iS = reshape(iS, ne, nPer);
    E(:,:,iLoop) = E(:,:,iLoop) + F*iS;
end

% `E` is ne-by-nPer-by-nLoop, permute to nPer-by-nLoop-by-ne.
E = permute(E, [2,3,1]);

for i = 1 : ne
    name = lsName{i};
    d.(name) = replace(TEMPLATE_SERIES, E(:,:,i), range(1), lsLabel{i});
end

return




    function doChkSize( )
        if nAlt>1 && nDraw>1 && nAlt~=nDraw
            utils.error('model:shockdb', ...
                ['Input argument NDraw is not compatible with the number ', ...
                'of alternative parameterizations in the model object.']);
        end
        
        if nShock>1 && nDraw>1 && nShock~=nDraw
            utils.error('model:shockdb', ...
                ['Input argument NDraw is not compatible with the number ', ...
                'of alternative data sets in the input database.']);
        end
        
        if nShock>1 && nAlt>1 && nAlt~=nShock
            utils.error('model:shockdb', ...
                ['The number of alternative data sets in the input database ', ...
                'is not compatible with the number ', ...
                'of alternative parameterizations in the model object.']);
        end
    end
end
