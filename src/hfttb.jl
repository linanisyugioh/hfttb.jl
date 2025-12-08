module hfttb
using CBinding
using Pkg.Artifacts
using FinancialStruct:cOnlyTBTickData,cSecurityTickData,cTickByTickData,HDataItem

# 使用 Artifacts 动态加载库文件
function __init__()
    # 确保 artifact 可用
    lib_dir = artifact"hfttb_lib"
    # 根据平台设置库路径
    global dlfile
    if Sys.iswindows()
        dlfile = joinpath(lib_dir, "hfttb_wrap.dll")
    elseif Sys.islinux()
        dlfile = joinpath(lib_dir, "libhfttb_wrap.so")
    end
    # 验证库文件是否存在
    if !isfile(dlfile)
        @error "hfttb library files not found. Please make sure the package is installed correctly."
    end
    global lib = Libc.Libdl.dlopen(dlfile)
end

#######################################strategy_api###############################################

"""
    hfttb_init(output_interval::Cint, create_options::Cint, price_dist_levels::Cint,
                    enable_tick_create::UInt8, int order_delay_ms::Cint, 
                    enable_open_call::UInt8, enable_order_match::UInt8)
 * 根据配置参数，初始化撮合工具API接口。
 *
 * @param output_interval     快照生成的最小时间间隔，单位毫秒
 * @param create_options      快照生成配置
 				enum TBTickCreateOption {
					TBTickCreate_BestChange = 1,				/// 是否在最优买/卖价格变化时立刻生成新的撮合快照
					TBTickCreate_OpenAuction = 2,			/// 是否在开盘集合竞价是生成模拟撮合快照
					TBTickCreate_OutPriceDists = 4,		/// 是否计算输出离开买/卖档最优价格固定一段距离的挂单量
					TBTickCreate_OutOrderNums = 8,			/// 是否计算输出买/卖盘对应的委托数量
				};
				create_options = 1 + 2 + 4 + 8
 * @param price_dist_levels   输出离开买/卖档最优价格挂单量的档位数，默认为10
"""
function hfttb_init(output_interval::Integer, create_options::Integer, price_dist_levels::Integer)
    sym = Libc.Libdl.dlsym(lib, :hfttb_init)   # 获得用于调用函数的符号
    ccall(sym, Cvoid, (Cint, Cint, Cint), output_interval, create_options, price_dist_levels)
end
export hfttb_init

"""
    hfttb_set_cb_callback(on_tick_cb::Function, user_data::Ptr{Cvoid}=C_NULL)
 * 设置策略退出事件回调函数
 *
 * @param on_tick_cb    撮合快照的回调方法
 * @param user_data     用户自定义参数
 *
 * @return              无返回
"""
function hfttb_set_cb_callback(on_tick_cb::Function, user_data::Ptr{Cvoid}=C_NULL)::Int
    global lib
    on_tick_cb_c = @cfunction($on_tick_cb, Cvoid, (Cptr{cSecurityTickData},Cptr{cOnlyTBTickData},Ptr{Cvoid}))
    sym = Libc.Libdl.dlsym(lib, :hfttb_set_cb)
    ccall(sym, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), on_tick_cb_c, user_data)
    return Int(0)
end
export  hfttb_set_cb_callback

"""
    hfttb_relase()
 *  解除撮合库
"""
function hfttb_relase()::Int
    sym = Libc.Libdl.dlsym(lib, :hfttb_relase)
    ccall(sym, Cvoid, ())
    return Int(0)
end
export hfttb_relase

"""
    hfttb_update(date::Integer)::Int
 *  更新撮合日期。
 *
 * @param date      日期
"""
function hfttb_update(date::Integer)::Int
    sym = Libc.Libdl.dlsym(lib, :hfttb_update)
    ccall(sym, Cvoid, (Cint, ), date)
    return Int(0)
end
export hfttb_update

"""
   hfttb_push_securitytick(symbol_idx::Integer, data::Cptr{cSecurityTickData})::Int
 * 输入tick数据用于撮合
 *
 * @param symbol_idx      标的索引
 * @param data            快照数据指针
 *
 * @return                返回0
"""
function hfttb_push_securitytick(data::Cptr{cSecurityTickData})::Int
    sym = Libc.Libdl.dlsym(lib, :hfttb_push_securitytick)
    ccall(sym, Cvoid, (Cptr{cSecurityTickData},), data)
    return Int(0)
end

function hfttb_push_securitytick(data::cSecurityTickData)::Int
    data_p = Ref{cSecurityTickData}(data)
    sym = Libc.Libdl.dlsym(lib, :hfttb_push_securitytick)
    ccall(sym, Cvoid, (Cptr{cSecurityTickData},), data_p)
    return Int(0)
end
export hfttb_push_securitytick

"""
   hfttb_push_tbt(symbol_idx::Integer, data::Cptr{cTickByTickData})::Int
 * 输入逐笔数据用于撮合
 *
 * @param symbol_idx      标的索引
 * @param data            快照数据指针
 *
 * @return                返回0
"""
function hfttb_push_tbt(data::Cptr{cTickByTickData})::Int
    sym = Libc.Libdl.dlsym(lib, :hfttb_push_tbt)
    ccall(sym, Cvoid, (Cptr{cTickByTickData},), data)
    return Int(0)
end

function hfttb_push_tbt(data::cTickByTickData)::Int
    data_p = Ref{cTickByTickData}(data)
    sym = Libc.Libdl.dlsym(lib, :hfttb_push_tbt)
    ccall(sym, Cvoid, (Cptr{cTickByTickData},), data_p)
    return Int(0)
end
export hfttb_push_tbt

"""
   hfttb_push_hdb_item(data::Ptr{HDataItem})::Int
 * 输入HDB数据用于撮合
 *
 * @param symbol_idx      标的索引
 * @param data            快照数据指针
 *
 * @return                返回0
"""
function hfttb_push_hdb_item(data::Ptr{HDataItem})::Int
    sym = Libc.Libdl.dlsym(lib, :hfttb_push_hdb_item)
    ccall(sym, Cvoid, (Ptr{HDataItem},), data)
    return Int(0)
end
export hfttb_push_tbt

"""
   hfttb_get_tick(symbol_idx::Integer, tick1::Cptr{cSecurityTickData}, tick2::Cptr{cOnlyTBTickData})::Cint
 * 获取撮合快照
 *
 * @param timepoint          定时任务执行时间: HHMMSS，精确到秒
 *
 * @return              成功返回0，失败返回-1
"""
#function hfttb_get_tick(symbol::String)
#    tick1 = Ref{NTuple{sizeof(cSecurityTickData),UInt8}}()
#    tick2 = Ref{NTuple{sizeof(cOnlyTBTickData),UInt8}}()
#    sym = Libc.Libdl.dlsym(lib, :hfttb_get_tick)
#    err = ccall(sym, Cint, (Ptr{UInt8}, Ptr{NTuple{sizeof(cSecurityTickData),UInt8}}, 
#    Ptr{NTuple{sizeof(cOnlyTBTickData),UInt8}}), symbol, tick1, tick2)
#    tick1 = convert(Cptr{cSecurityTickData}, tick1)
#    tick2 = convert(Cptr{cOnlyTBTickData}, tick2)
#    if err == 0
#        return (tick1[], tick2[])
#    else
#        return ()
#    end
#end

function hfttb_get_tick(symbol::String)
    tick1 = Ref{cSecurityTickData}(cSecurityTickData())
    tick2 = Ref{cOnlyTBTickData}(cOnlyTBTickData())
    sym = Libc.Libdl.dlsym(lib, :hfttb_get_tick)
    err = ccall(sym, Cint, (Ptr{UInt8}, Cptr{cSecurityTickData}, 
    Cptr{cOnlyTBTickData}), symbol, tick1, tick2)
    if err == 0
        return (tick1[], tick2[])
    else
        return ()
    end
end
export hfttb_get_tick

"""
    hfttb_refresh_tick(symbol_idx::Integer)::Int
 * 刷新快照
 *
 * @param symbol_idx   标的索引
"""
function hfttb_refresh_tick(symbol::String)::Int
    sym = Libc.Libdl.dlsym(lib, :hfttb_refresh_tick)
    ccall(sym, Cvoid, (Ptr{UInt8}, ), symbol)
    return Int(0)
end
export hfttb_refresh_tick

end
