package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdHlCard;
import com.eerp.master.mapper.MdHlCardMapper;
import com.eerp.master.service.HlCardService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class HlCardServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdHlCardMapper mdHlCardMapper;

    @InjectMocks private HlCardService hlCardService;

    private static final String BO_CODE = "MD_HL_CARD";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存色卡：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = hlCardService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存色卡数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = hlCardService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用色卡：更新status=1")
    void testEnable() {
        MdHlCard hlCard = new MdHlCard();
        hlCard.setId(ID);
        hlCard.setStatus(0);
        when(mdHlCardMapper.selectById(ID)).thenReturn(hlCard);

        hlCardService.enable(ID);

        assertEquals(1, hlCard.getStatus());
        verify(mdHlCardMapper).updateById(hlCard);
    }

    @Test
    @DisplayName("查询色卡详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = hlCardService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询色卡：委托 Mapper")
    void testFindById() {
        MdHlCard hlCard = new MdHlCard();
        hlCard.setId(ID);
        when(mdHlCardMapper.selectById(ID)).thenReturn(hlCard);

        MdHlCard result = hlCardService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
